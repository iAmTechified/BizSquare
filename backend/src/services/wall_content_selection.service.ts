import { pool } from '../db/pool';
import { InterestDemandService } from './interest_demand.service';
import { ContentPoolType, WallSessionItemPayload } from '../types/interest_engine.types';

export class WallContentSelectionService {
  /**
   * Builds an intelligent, diverse, non-repetitive daily wall session
   */
  static async selectSessionContent(params: {
    userId: string;
    targetCount?: number;
    cooldownDays?: number;
  }): Promise<{ items: WallSessionItemPayload[]; targetMix: Record<string, number> }> {
    const { userId, targetCount = 5, cooldownDays = 14 } = params;

    // 1. Fetch Current Demand profile for user
    const demand = await InterestDemandService.getCurrentDemand(userId);
    const topTaxonomyIds = [
      ...demand.demand_tier_high.map(d => d.taxonomy_id),
      ...demand.demand_tier_medium.map(d => d.taxonomy_id),
    ];

    // 2. Fetch recently seen content IDs for cooldown
    const seenQuery = `
      SELECT DISTINCT content_id 
      FROM wall_session_items wsi
      JOIN wall_sessions ws ON ws.session_id = wsi.session_id
      WHERE ws.user_id = $1 AND ws.started_at > NOW() - ($2 || ' days')::INTERVAL
    `;
    const { rows: seenRows } = await pool.query(seenQuery, [userId, cooldownDays]);
    const seenContentIds = new Set(seenRows.map(r => r.content_id));

    // 3. Fetch related taxonomy IDs from semantic relationships
    let relatedTaxonomyIds: string[] = [];
    if (topTaxonomyIds.length > 0) {
      const relQuery = `
        SELECT DISTINCT target_id 
        FROM interest_taxonomy_relationships 
        WHERE source_id = ANY($1) AND target_id != ALL($1)
      `;
      const { rows: relRows } = await pool.query(relQuery, [topTaxonomyIds]);
      relatedTaxonomyIds = relRows.map(r => r.target_id);
    }

    // 4. Fetch all active content items with options and taxonomies
    const activeContentQuery = `
      SELECT 
        ci.id, ci.format, ci.title_prompt, ci.description, ci.media_url,
        ci.media_type, ci.context_type,
        ctl.taxonomy_id, t.name as taxonomy_name, t.slug as taxonomy_slug
      FROM content_items ci
      JOIN content_taxonomy_links ctl ON ctl.content_id = ci.id AND ctl.is_primary = TRUE
      JOIN interest_taxonomies t ON t.id = ctl.taxonomy_id
      WHERE ci.status = 'ACTIVE'
    `;
    const { rows: allActiveContent } = await pool.query(activeContentQuery);

    if (allActiveContent.length === 0) {
      return { items: [], targetMix: { personalized: 0.4, related: 0.25, exploration: 0.2, broad: 0.15 } };
    }

    // Classify content items into 4 Candidate Pools
    const personalizedPool: any[] = [];
    const relatedPool: any[] = [];
    const explorationPool: any[] = [];
    const broadPool: any[] = [];

    allActiveContent.forEach(item => {
      const isSeen = seenContentIds.has(item.id);
      const isPersonalized = topTaxonomyIds.includes(item.taxonomy_id);
      const isRelated = relatedTaxonomyIds.includes(item.taxonomy_id);

      const candidate = { ...item, isSeen };

      if (isPersonalized) {
        personalizedPool.push(candidate);
      } else if (isRelated) {
        relatedPool.push(candidate);
      } else if (item.context_type === 'general' || item.context_type === 'lifestyle') {
        broadPool.push(candidate);
      } else {
        explorationPool.push(candidate);
      }
    });

    // Helper: Select from pool with unseen priority + non-deterministic shuffle
    const pickFromPool = (
      pool: any[],
      count: number,
      selectedIds: Set<string>,
      selectedTaxonomies: Set<string>,
      poolType: ContentPoolType
    ): (WallSessionItemPayload & { taxonomy_id: string })[] => {
      // Prioritize unseen items
      const available = pool.filter(p => !selectedIds.has(p.id));
      const unseen = available.filter(p => !p.isSeen);
      const seen = available.filter(p => p.isSeen);

      // Shuffle candidates within tier
      const candidates = [...unseen.sort(() => Math.random() - 0.5), ...seen.sort(() => Math.random() - 0.5)];

      const picked: (WallSessionItemPayload & { taxonomy_id: string })[] = [];
      for (const item of candidates) {
        if (picked.length >= count) break;

        // Topic diversity: avoid showing the same taxonomy twice in one session unless necessary
        if (!selectedTaxonomies.has(item.taxonomy_id) || candidates.length <= count) {
          selectedIds.add(item.id);
          selectedTaxonomies.add(item.taxonomy_id);
          picked.push({
            content_id: item.id,
            format: item.format,
            title_prompt: item.title_prompt,
            description: item.description,
            media_url: item.media_url,
            media_type: item.media_type,
            context_type: item.context_type,
            pool_type: poolType,
            options: [], // populated below
            order_index: 0,
            taxonomy_id: item.taxonomy_id,
          });
        }
      }
      return picked;
    };

    const selectedIds = new Set<string>();
    const selectedTaxonomies = new Set<string>();

    // Calculate slots according to 40% / 25% / 20% / 15% distribution
    const personalizedCount = Math.max(1, Math.round(targetCount * 0.40));
    const relatedCount = Math.max(1, Math.round(targetCount * 0.25));
    const explorationCount = Math.max(1, Math.round(targetCount * 0.20));
    const broadCount = Math.max(1, targetCount - (personalizedCount + relatedCount + explorationCount));

    const pItems = pickFromPool(personalizedPool, personalizedCount, selectedIds, selectedTaxonomies, 'PERSONALIZED');
    const rItems = pickFromPool(relatedPool, relatedCount, selectedIds, selectedTaxonomies, 'RELATED');
    const eItems = pickFromPool(explorationPool, explorationCount, selectedIds, selectedTaxonomies, 'EXPLORATION');
    const bItems = pickFromPool(broadPool, broadCount, selectedIds, selectedTaxonomies, 'BROAD');

    // Fill remaining slots if any pool was exhausted
    let sessionCandidates = [...pItems, ...rItems, ...eItems, ...bItems];
    if (sessionCandidates.length < targetCount) {
      const leftovers = pickFromPool(allActiveContent, targetCount - sessionCandidates.length, selectedIds, selectedTaxonomies, 'BROAD');
      sessionCandidates = [...sessionCandidates, ...leftovers];
    }

    // Format Diversity: Avoid identical consecutive formats by reordering
    const formattedList: (WallSessionItemPayload & { taxonomy_id: string })[] = [];
    const remaining = [...sessionCandidates];

    while (remaining.length > 0) {
      const lastItem = formattedList.length > 0 ? formattedList[formattedList.length - 1] : null;
      const lastFormat = lastItem ? lastItem.format : null;
      let nextIndex = remaining.findIndex(item => item && item.format !== lastFormat);
      if (nextIndex === -1) nextIndex = 0; // Fallback if all remaining have same format

      const spliced = remaining.splice(nextIndex, 1);
      const chosen = spliced[0];
      if (chosen) {
        chosen.order_index = formattedList.length + 1;
        formattedList.push(chosen);
      }
    }

    // Fetch options for all chosen content items
    const chosenIds = formattedList.map(f => f.content_id);
    const optionsQuery = `
      SELECT id, content_id, option_key, label, subtext, media_url, order_index
      FROM content_options
      WHERE content_id = ANY($1)
      ORDER BY order_index ASC
    `;
    const { rows: optionRows } = await pool.query(optionsQuery, [chosenIds]);

    const finalItems: WallSessionItemPayload[] = formattedList.map(item => ({
      content_id: item.content_id,
      format: item.format,
      title_prompt: item.title_prompt,
      description: item.description || undefined,
      media_url: item.media_url || undefined,
      media_type: item.media_type,
      context_type: item.context_type,
      pool_type: item.pool_type,
      order_index: item.order_index,
      options: optionRows
        .filter(o => o.content_id === item.content_id)
        .map(o => ({
          option_key: o.option_key,
          label: o.label,
          subtext: o.subtext || undefined,
          media_url: o.media_url || undefined,
        })),
    }));

    return {
      items: finalItems,
      targetMix: {
        personalized: 0.40,
        related: 0.25,
        exploration: 0.20,
        broad: 0.15,
      },
    };
  }
}
