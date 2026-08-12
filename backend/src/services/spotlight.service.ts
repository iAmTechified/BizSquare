import { pool } from '../db/pool';

export interface SpotlightCurrentState {
  campaignId: string | null;
  isMyTurn: boolean;
  user: {
    id: string;
    businessName: string;
    fullName: string;
    phoneNumber?: string | undefined;
    avatarId: number;
    primaryOffer: string;
  } | null;
  content: {
    title: string;
    promoText: string;
    caption: string;
    flyerUrl?: string | undefined;
  } | null;
  targetParticipants: number;
  participantCount: number;
  hasParticipated: boolean;
  startDate: string;
  endDate: string;
}

export class SpotlightService {
  /**
   * Fetches or automatically schedules the current active Spotlight campaign.
   */
  static async getCurrentSpotlight(userId: string): Promise<SpotlightCurrentState> {
    const client = await pool.connect();
    try {
      // 1. Fetch active campaign for today
      let { rows: [campaign] } = await client.query(`
        SELECT 
          sc.*,
          u.business_name,
          u.full_name,
          u.phone_number,
          u.avatar_id,
          COALESCE(mn.name, 'General Business') as primary_offer
        FROM spotlight_campaigns sc
        JOIN users u ON u.id = sc.user_id
        LEFT JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
        LEFT JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
        WHERE sc.is_active = TRUE 
          AND sc.start_date <= CURRENT_DATE 
          AND sc.end_date >= CURRENT_DATE
        ORDER BY sc.created_at DESC
        LIMIT 1
      `);

      // 2. If no campaign exists for today, select a candidate user and initialize one
      if (!campaign) {
        const { rows: [candidate] } = await client.query(`
          SELECT 
            u.id, u.business_name, u.full_name, u.phone_number, u.avatar_id,
            COALESCE(mn.name, 'Business Owner') as primary_offer
          FROM users u
          LEFT JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
          LEFT JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
          WHERE u.is_active = TRUE AND u.onboarding_completed = TRUE
          ORDER BY RANDOM()
          LIMIT 1
        `);

        if (candidate) {
          const defaultTitle = `${candidate.business_name || candidate.full_name} Spotlight`;
          const defaultPromo = `Check out ${candidate.business_name || candidate.full_name} on BizSquare! Verified provider for ${candidate.primary_offer}.`;
          const defaultCaption = `Connecting with top verified business owners in Nigeria. Reach out to ${candidate.business_name || candidate.full_name} for ${candidate.primary_offer}. #GrowTogether #BizSquare`;

          const { rows: [newCamp] } = await client.query(`
            INSERT INTO spotlight_campaigns (
              user_id, title, promo_text, caption, start_date, end_date, target_participants, is_active
            ) VALUES (
              $1, $2, $3, $4, CURRENT_DATE, CURRENT_DATE + INTERVAL '6 days', 48, TRUE
            ) RETURNING *
          `, [candidate.id, defaultTitle, defaultPromo, defaultCaption]);

          campaign = {
            ...newCamp,
            business_name: candidate.business_name,
            full_name: candidate.full_name,
            phone_number: candidate.phone_number,
            avatar_id: candidate.avatar_id,
            primary_offer: candidate.primary_offer,
          };
        }
      }

      if (!campaign) {
        return {
          campaignId: null,
          isMyTurn: false,
          user: null,
          content: null,
          targetParticipants: 48,
          participantCount: 0,
          hasParticipated: false,
          startDate: new Date().toISOString(),
          endDate: new Date().toISOString(),
        };
      }

      // 3. Count total participants for this campaign
      const { rows: [{ count: partCount }] } = await client.query(
        `SELECT COUNT(*) FROM spotlight_participations WHERE campaign_id = $1`,
        [campaign.id]
      );

      // 4. Check if current user has participated
      const { rows: myPart } = await client.query(
        `SELECT id FROM spotlight_participations WHERE campaign_id = $1 AND user_id = $2`,
        [campaign.id, userId]
      );

      const isMyTurn = campaign.user_id === userId;
      const hasParticipated = myPart.length > 0;

      return {
        campaignId: campaign.id,
        isMyTurn,
        user: {
          id: campaign.user_id,
          businessName: campaign.business_name,
          fullName: campaign.full_name,
          phoneNumber: campaign.phone_number || undefined,
          avatarId: campaign.avatar_id || 1,
          primaryOffer: campaign.primary_offer,
        },
        content: {
          title: campaign.title,
          promoText: campaign.promo_text,
          caption: campaign.caption,
          flyerUrl: campaign.flyer_url || undefined,
        },
        targetParticipants: campaign.target_participants || 48,
        participantCount: parseInt(partCount, 10) || 0,
        hasParticipated,
        startDate: campaign.start_date,
        endDate: campaign.end_date,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Records user participation (sharing to WhatsApp)
   */
  static async participate(userId: string, campaignId: string): Promise<{ success: boolean; message: string; pointsAwarded: number }> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Check if already participated
      const { rows: existing } = await client.query(
        `SELECT id FROM spotlight_participations WHERE campaign_id = $1 AND user_id = $2`,
        [campaignId, userId]
      );

      if (existing.length > 0) {
        await client.query('COMMIT');
        return { success: true, message: 'Already participated', pointsAwarded: 0 };
      }

      // Insert participation record
      await client.query(`
        INSERT INTO spotlight_participations (campaign_id, user_id, channel, verified)
        VALUES ($1, $2, 'whatsapp_status', TRUE)
      `, [campaignId, userId]);

      // Award Akawo points
      await client.query(`
        INSERT INTO akawo_ledger (user_id, points_awarded, transaction_type, verified_by_bot)
        VALUES ($1, 2, 'spotlight_share', TRUE)
      `, [userId]);

      await client.query('COMMIT');
      return { success: true, message: 'Participation verified! +2 Akawo Points awarded.', pointsAwarded: 2 };
    } catch (err: any) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Sets content when it is user's turn in Spotlight
   */
  static async setMyContent(
    userId: string,
    title: string,
    promoText: string,
    caption: string,
    flyerUrl?: string
  ): Promise<void> {
    await pool.query(`
      UPDATE spotlight_campaigns
      SET title = $1, promo_text = $2, caption = $3, flyer_url = $4
      WHERE user_id = $5 AND is_active = TRUE
    `, [title, promoText, caption, flyerUrl || null, userId]);
  }

  /**
   * Fetches Spotlight History (Mine & Others)
   */
  static async getHistory(userId: string) {
    // 1. Mine (Campaigns created by user and participants who shared for them)
    const { rows: mineCampaigns } = await pool.query(`
      SELECT 
        sc.id as campaign_id, sc.title, sc.promo_text, sc.caption, sc.flyer_url,
        sc.start_date, sc.end_date, sc.target_participants,
        COUNT(sp.id) as participant_count
      FROM spotlight_campaigns sc
      LEFT JOIN spotlight_participations sp ON sp.campaign_id = sc.id
      WHERE sc.user_id = $1
      GROUP BY sc.id
      ORDER BY sc.start_date DESC
    `, [userId]);

    // 2. Others (Campaigns user participated in for other business owners)
    const { rows: othersParticipations } = await pool.query(`
      SELECT 
        sp.id as participation_id, sp.created_at as participated_at,
        sc.title, sc.promo_text, sc.caption, sc.flyer_url,
        u.business_name as creator_business_name,
        u.full_name as creator_name,
        u.avatar_id as creator_avatar,
        COALESCE(mn.name, 'Business') as creator_primary_offer
      FROM spotlight_participations sp
      JOIN spotlight_campaigns sc ON sc.id = sp.campaign_id
      JOIN users u ON u.id = sc.user_id
      LEFT JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
      LEFT JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      WHERE sp.user_id = $1
      ORDER BY sp.created_at DESC
    `, [userId]);

    return {
      mine: mineCampaigns.map(c => ({
        campaignId: c.campaign_id,
        title: c.title,
        promoText: c.promo_text,
        caption: c.caption,
        flyerUrl: c.flyer_url,
        startDate: c.start_date,
        endDate: c.end_date,
        participantCount: parseInt(c.participant_count, 10) || 0,
        targetParticipants: c.target_participants,
      })),
      others: othersParticipations.map(p => ({
        participationId: p.participation_id,
        participatedAt: p.participated_at,
        title: p.title,
        promoText: p.promo_text,
        caption: p.caption,
        flyerUrl: p.flyer_url,
        creatorBusinessName: p.creator_business_name,
        creatorName: p.creator_name,
        creatorAvatar: p.creator_avatar,
        creatorPrimaryOffer: p.creator_primary_offer,
      })),
    };
  }
}
