import { pool } from '../db/pool';
import { ContentFormat, ContextType } from '../types/interest_engine.types';
import { InterestTaxonomyService } from './interest_taxonomy.service';
import { ContentValidationService, RawGeneratedItem } from './content_validation.service';
import { ContentDuplicateService } from './content_duplicate.service';

export class ContentGenerationService {
  /**
   * Generates a batch of structured interaction instruments for a taxonomy node
   */
  static async generateBatch(params: {
    taxonomyId: string;
    formats: ContentFormat[];
    quantity: number;
    contextType?: ContextType;
    targetAudience?: string;
    tone?: string;
    createdBy?: string;
  }): Promise<{ batchId: string; generatedCount: number; reviewCount: number; rejectedCount: number }> {
    const {
      taxonomyId,
      formats = ['THIS_OR_THAT', 'PICK_ONE', 'WOULD_YOU', 'REACTION_CARD', 'SCENARIO'],
      quantity = 10,
      contextType = 'mixed',
      targetAudience = 'general',
      createdBy,
    } = params;

    const taxonomy = await InterestTaxonomyService.getTaxonomyByIdOrSlug(taxonomyId);
    if (!taxonomy) throw new Error(`Taxonomy node not found: ${taxonomyId}`);

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Create batch record
      const batchQuery = `
        INSERT INTO content_generation_batches (
          taxonomy_id, formats, context_type, target_audience, target_quantity, status, created_by
        ) VALUES ($1, $2, $3, $4, $5, 'GENERATING', $6)
        RETURNING id
      `;
      const { rows: batchRows } = await client.query(batchQuery, [
        taxonomy.id,
        formats,
        contextType,
        targetAudience,
        quantity,
        createdBy || null,
      ]);
      const batchId = batchRows[0].id;

      // 2. Synthesize structured items algorithmically / template-based across formats
      const candidateItems = this.synthesizeTemplates(taxonomy, formats, quantity, contextType);

      let generatedCount = 0;
      let reviewCount = 0;
      let rejectedCount = 0;

      for (const item of candidateItems) {
        generatedCount++;

        // Automated Validation
        const val = ContentValidationService.validateItem(item);
        if (!val.isValid) {
          rejectedCount++;
          continue;
        }

        // Duplicate Check
        const dup = await ContentDuplicateService.checkDuplicate(item.title_prompt, taxonomy.id);
        if (dup.isDuplicate) {
          rejectedCount++;
          continue;
        }

        // Insert Content Item in 'REVIEW' status
        const insertContentQuery = `
          INSERT INTO content_items (
            format, status, title_prompt, description, context_type,
            target_audience, batch_id, created_by
          ) VALUES ($1, 'REVIEW', $2, $3, $4, $5, $6, $7)
          RETURNING id
        `;
        const { rows: cRows } = await client.query(insertContentQuery, [
          item.format,
          item.title_prompt,
          item.description || null,
          item.context_type || 'general',
          targetAudience,
          batchId,
          createdBy || null,
        ]);
        const contentId = cRows[0].id;
        reviewCount++;

        // Link primary taxonomy
        await client.query(
          `INSERT INTO content_taxonomy_links (content_id, taxonomy_id, is_primary) VALUES ($1, $2, TRUE)`,
          [contentId, taxonomy.id]
        );

        // Insert options & signal mappings
        for (let i = 0; i < item.options.length; i++) {
          const opt = item.options[i];
          if (!opt) continue;
          const optQuery = `
            INSERT INTO content_options (content_id, option_key, label, subtext, order_index)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id
          `;
          const { rows: optRows } = await client.query(optQuery, [
            contentId,
            opt.option_key,
            opt.label,
            opt.subtext || null,
            i + 1,
          ]);
          const optionId = optRows[0].id;

          for (const sig of opt.signals) {
            let targetTaxId = taxonomy.id;
            if (sig.taxonomy_slug && sig.taxonomy_slug !== taxonomy.slug) {
              const matched = await InterestTaxonomyService.getTaxonomyByIdOrSlug(sig.taxonomy_slug);
              if (matched) targetTaxId = matched.id;
            }

            await client.query(
              `INSERT INTO content_signal_mappings (
                content_id, option_id, taxonomy_id, signal_type, weight, context
              ) VALUES ($1, $2, $3, $4, $5, $6)`,
              [contentId, optionId, targetTaxId, sig.signal_type, sig.weight, item.context_type]
            );
          }
        }
      }

      // Update batch status
      await client.query(
        `UPDATE content_generation_batches SET
          generated_quantity = $1,
          status = 'COMPLETED'
        WHERE id = $2`,
        [generatedCount, batchId]
      );

      await client.query('COMMIT');
      await InterestTaxonomyService.refreshContentCounts();

      return { batchId, generatedCount, reviewCount, rejectedCount };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * High-diversity template synthesizer generating structured instruments tailored to taxonomy
   */
  private static synthesizeTemplates(
    taxonomy: { id: string; name: string; slug: string },
    formats: ContentFormat[],
    quantity: number,
    contextType: ContextType
  ): RawGeneratedItem[] {
    const items: RawGeneratedItem[] = [];
    const name = taxonomy.name;

    for (let i = 0; i < quantity; i++) {
      const format = formats[i % formats.length];

      switch (format) {
        case 'THIS_OR_THAT':
          items.push({
            format: 'THIS_OR_THAT',
            title_prompt: `When exploring ${name}, which aspect is most crucial for you right now?`,
            description: `Contrasting top-tier premium execution vs budget agility in ${name}.`,
            context_type: contextType,
            options: [
              {
                option_key: 'opt_a',
                label: `Premium Top-Tier Quality in ${name}`,
                subtext: 'High durability & elite performance',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'opt_b',
                label: `Fast & Cost-Effective Value in ${name}`,
                subtext: 'Affordable & swift turnaround',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
            ],
          });
          break;

        case 'WOULD_YOU':
          items.push({
            format: 'WOULD_YOU',
            title_prompt: `Would you test a dedicated, verified solution for ${name} this quarter?`,
            description: `Evaluating user curiosity and readiness in ${name}.`,
            context_type: contextType,
            options: [
              {
                option_key: 'yes',
                label: 'Definitely Yes 🔥',
                subtext: 'Actively searching for solutions',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'maybe',
                label: 'Maybe / Curious 👀',
                subtext: 'Need to review terms & proof',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'weak_positive', weight: 0.5 }],
              },
              {
                option_key: 'no',
                label: 'Not Interested',
                subtext: 'No current need',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'negative', weight: -0.5 }],
              },
            ],
          });
          break;

        case 'PICK_ONE':
          items.push({
            format: 'PICK_ONE',
            title_prompt: `What is your biggest daily challenge or focus area in ${name}?`,
            description: `Identifying specific sub-priorities within ${name}.`,
            context_type: contextType,
            options: [
              {
                option_key: 'opt_1',
                label: `Finding Reliable Suppliers for ${name}`,
                subtext: 'Verified sourcing & pricing',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'opt_2',
                label: `Speed & Express Delivery in ${name}`,
                subtext: 'Fast logistics & execution',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'opt_3',
                label: `Scaling Quality & Customer Trust`,
                subtext: 'Reputation & long-term retention',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
            ],
          });
          break;

        case 'SCENARIO':
          items.push({
            format: 'SCENARIO',
            title_prompt: `Imagine you have allocated dedicated capital to improve ${name}. Where does it go?`,
            description: `Dilemma exploring operational bottlenecks and high-leverage growth.`,
            context_type: contextType,
            options: [
              {
                option_key: 'scen_a',
                label: `Acquire Next-Gen Tools & Equipment`,
                subtext: 'Modernize tech & gear',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'scen_b',
                label: `Expand Strategic Partnerships & Network`,
                subtext: 'Collaborate with top peers',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'scen_c',
                label: `Branding & Digital Visibility`,
                subtext: 'Dominate customer attention',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
            ],
          });
          break;

        case 'REACTION_CARD':
          items.push({
            format: 'REACTION_CARD',
            title_prompt: `Specialized High-Efficiency Workflow & Verified Network in ${name}`,
            description: `Visual reaction card capturing raw initial sentiment.`,
            context_type: contextType,
            options: [
              {
                option_key: 'react_love',
                label: '❤️ Highly Interested',
                subtext: 'Essential to my goals',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'react_curious',
                label: '👀 Curious to Learn More',
                subtext: 'Looking for case studies',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'weak_positive', weight: 0.5 }],
              },
              {
                option_key: 'react_skip',
                label: '⏭️ Skip for Now',
                subtext: 'No current priority',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'neutral', weight: 0.0 }],
              },
            ],
          });
          break;

        case 'COMPARE':
          items.push({
            format: 'COMPARE',
            title_prompt: `Comparing two distinct methodologies in ${name}: which resonates more?`,
            description: `Comparative choice between direct hands-on vs automated managed service.`,
            context_type: contextType,
            options: [
              {
                option_key: 'opt_a',
                label: `Hands-On Custom Control`,
                subtext: 'Tailored specifically to unique specs',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'opt_b',
                label: `Automated Turnkey Speed`,
                subtext: 'Instant turnaround with zero hassle',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
            ],
          });
          break;

        case 'QUICK_OPINION':
          items.push({
            format: 'QUICK_OPINION',
            title_prompt: `Is investing in premium professional solutions for ${name} essential for long-term growth?`,
            description: `Evaluative opinion on investment value in ${name}.`,
            context_type: contextType,
            options: [
              {
                option_key: 'opt_def',
                label: 'Definitely Essential 💯',
                subtext: 'Non-negotiable for real success',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'positive', weight: 1.0 }],
              },
              {
                option_key: 'opt_maybe',
                label: 'Depends on Scale',
                subtext: 'Only for mature operations',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'weak_positive', weight: 0.4 }],
              },
              {
                option_key: 'opt_no',
                label: 'Overrated',
                subtext: 'Standard methods suffice',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'negative', weight: -0.4 }],
              },
            ],
          });
          break;

        case 'INTENT_CHOICE':
        default:
          items.push({
            format: 'INTENT_CHOICE',
            title_prompt: `If a verified opportunity in ${name} became available today:`,
            description: `Commercial urgency and action trigger.`,
            context_type: contextType,
            options: [
              {
                option_key: 'act_now',
                label: 'Take Action Immediately ⚡',
                subtext: 'Ready to connect & transact',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'intent', weight: 1.5 }],
              },
              {
                option_key: 'act_wait',
                label: 'Save & Review Later',
                subtext: 'Evaluating budget and timing',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'weak_positive', weight: 0.5 }],
              },
              {
                option_key: 'act_alt',
                label: 'Explore Other Categories',
                subtext: 'Focusing on different priorities',
                signals: [{ taxonomy_slug: taxonomy.slug, signal_type: 'neutral', weight: 0.2 }],
              },
            ],
          });
          break;
      }
    }

    return items;
  }
}
