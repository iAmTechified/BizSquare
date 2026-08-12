import { pool } from '../db/pool';
import { NotificationService, NotificationEvents } from './notification.service';
import { SpotlightNotificationService } from './spotlight_notification.service';

export interface SpotlightRequirement {
  prompt: string;
  maxCharacters: number;
  placeholder: string;
}

export interface SpotlightCurrentState {
  campaignId: string | null;
  isMyTurn: boolean;
  turnStatus: 'my_turn' | 'not_my_turn' | 'waiting';
  cycleNumber: number;
  cycleStartDate: string;
  cycleEndDate: string;
  submissionStatus: 'not_submitted' | 'pending' | 'verified' | 'needs_changes';
  rejectionReason: string | null;
  submissionRequirement: SpotlightRequirement;
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
}

export interface SpotlightParticipant {
  id: string;
  businessName: string;
  fullName: string;
  avatarId: number;
  primaryOffer: string;
  participatedAt: string;
}

export interface SubmitSpotlightPayload {
  idempotencyKey?: string;
  title: string;
  promoText: string;
  caption: string;
  flyerUrl?: string;
}

const DEFAULT_REQUIREMENT: SpotlightRequirement = {
  prompt: 'What are you sharing this cycle? Showcase your best product, offer, or service to the network.',
  maxCharacters: 300,
  placeholder: "e.g. 20% discount on all Men's Native Wears this week with nationwide delivery...",
};

export class SpotlightService {
  /**
   * Fetches the server-authoritative active Spotlight campaign and turn state.
   */
  static async getCurrentSpotlight(userId: string): Promise<SpotlightCurrentState> {
    const client = await pool.connect();
    try {
      // 1. First check if current user has an active/pending campaign assigned to them
      let { rows: [userCampaign] } = await client.query(`
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
        WHERE sc.user_id = $1 AND sc.is_active = TRUE
          AND sc.start_date <= CURRENT_DATE 
          AND sc.end_date >= CURRENT_DATE
        ORDER BY sc.created_at DESC
        LIMIT 1
      `, [userId]);

      // 2. If user doesn't have an active campaign, fetch general active community campaign
      let campaign = userCampaign;
      if (!campaign) {
        const { rows: [activeCamp] } = await client.query(`
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
        campaign = activeCamp;
      }

      // 3. Auto-seed if no campaign is currently active
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
              user_id, title, promo_text, caption, start_date, end_date, target_participants, is_active,
              submission_status, cycle_number, submission_requirement
            ) VALUES (
              $1, $2, $3, $4, CURRENT_DATE, CURRENT_DATE + INTERVAL '6 days', 48, TRUE,
              'verified', 1, $5
            ) RETURNING *
          `, [candidate.id, defaultTitle, defaultPromo, defaultCaption, JSON.stringify(DEFAULT_REQUIREMENT)]);

          campaign = {
            ...newCamp,
            business_name: candidate.business_name,
            full_name: candidate.full_name,
            phone_number: candidate.phone_number,
            avatar_id: candidate.avatar_id,
            primary_offer: candidate.primary_offer,
          };

          // Notify the featured user that it's their Spotlight turn
          setImmediate(async () => {
            try {
              const cycleEndDate = new Date(Date.now() + 6 * 24 * 60 * 60 * 1000).toLocaleDateString('en-NG', { month: 'short', day: 'numeric' });
              await NotificationEvents.spotlightTurn({
                userId: candidate.id,
                cycleId: newCamp.id,
                cycleEndDate,
              });
            } catch (_) {}
          });
        }
      }

      if (!campaign) {
        return {
          campaignId: null,
          isMyTurn: false,
          turnStatus: 'waiting',
          cycleNumber: 1,
          cycleStartDate: new Date().toISOString(),
          cycleEndDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000).toISOString(),
          submissionStatus: 'not_submitted',
          rejectionReason: null,
          submissionRequirement: DEFAULT_REQUIREMENT,
          user: null,
          content: null,
          targetParticipants: 48,
          participantCount: 0,
          hasParticipated: false,
        };
      }

      // Count total participants
      const { rows: [{ count: partCount }] } = await client.query(
        `SELECT COUNT(*) FROM spotlight_participations WHERE campaign_id = $1`,
        [campaign.id]
      );

      // Check if current user participated
      const { rows: myPart } = await client.query(
        `SELECT id FROM spotlight_participations WHERE campaign_id = $1 AND user_id = $2`,
        [campaign.id, userId]
      );

      const isMyTurn = campaign.user_id === userId;
      const turnStatus = isMyTurn ? 'my_turn' : 'not_my_turn';
      const hasParticipated = myPart.length > 0;

      let requirement = DEFAULT_REQUIREMENT;
      if (campaign.submission_requirement) {
        try {
          requirement = typeof campaign.submission_requirement === 'string'
            ? JSON.parse(campaign.submission_requirement)
            : campaign.submission_requirement;
        } catch (_) {}
      }

      return {
        campaignId: campaign.id,
        isMyTurn,
        turnStatus,
        cycleNumber: campaign.cycle_number || 1,
        cycleStartDate: campaign.start_date,
        cycleEndDate: campaign.end_date,
        submissionStatus: (campaign.submission_status as any) || 'verified',
        rejectionReason: campaign.rejection_reason || null,
        submissionRequirement: requirement,
        user: {
          id: campaign.user_id,
          businessName: campaign.business_name || 'Partner',
          fullName: campaign.full_name || '',
          phoneNumber: campaign.phone_number || undefined,
          avatarId: campaign.avatar_id || 1,
          primaryOffer: campaign.primary_offer || 'Verified Business',
        },
        content: {
          title: campaign.title || 'Spotlight Feature',
          promoText: campaign.promo_text || '',
          caption: campaign.caption || '',
          flyerUrl: campaign.flyer_url || undefined,
        },
        targetParticipants: campaign.target_participants || 48,
        participantCount: parseInt(partCount, 10) || 0,
        hasParticipated,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Idempotent Spotlight Submission Handler.
   */
  static async submitSpotlight(userId: string, payload: SubmitSpotlightPayload): Promise<{
    success: boolean;
    campaignId: string;
    submissionStatus: string;
    message: string;
  }> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Check idempotency key if provided
      if (payload.idempotencyKey) {
        const { rows: existingKey } = await client.query(
          `SELECT id, submission_status FROM spotlight_campaigns WHERE idempotency_key = $1 AND user_id = $2`,
          [payload.idempotencyKey, userId]
        );
        if (existingKey.length > 0) {
          await client.query('COMMIT');
          return {
            success: true,
            campaignId: existingKey[0].id,
            submissionStatus: existingKey[0].submission_status,
            message: 'Spotlight already submitted (Idempotent response).',
          };
        }
      }

      // Check if user has an existing active campaign
      const { rows: userCamps } = await client.query(
        `SELECT id FROM spotlight_campaigns WHERE user_id = $1 AND is_active = TRUE ORDER BY created_at DESC LIMIT 1`,
        [userId]
      );

      let campaignId: string;
      if (userCamps.length > 0) {
        campaignId = userCamps[0].id;
        await client.query(`
          UPDATE spotlight_campaigns
          SET title = $1, promo_text = $2, caption = $3, flyer_url = $4,
              submission_status = 'pending', idempotency_key = $5
          WHERE id = $6
        `, [payload.title, payload.promoText, payload.caption, payload.flyerUrl || null, payload.idempotencyKey || null, campaignId]);
      } else {
        const { rows: [created] } = await client.query(`
          INSERT INTO spotlight_campaigns (
            user_id, title, promo_text, caption, flyer_url, start_date, end_date,
            target_participants, is_active, submission_status, idempotency_key, cycle_number
          ) VALUES (
            $1, $2, $3, $4, $5, CURRENT_DATE, CURRENT_DATE + INTERVAL '6 days',
            48, TRUE, 'pending', $6, 1
          ) RETURNING id
        `, [userId, payload.title, payload.promoText, payload.caption, payload.flyerUrl || null, payload.idempotencyKey || null]);
        campaignId = created.id;
      }

      await client.query('COMMIT');

      // Cancel all outstanding reminders for this turn (Section 5 & 11)
      setImmediate(async () => {
        try {
          await SpotlightNotificationService.cancelRemindersForTurn(userId, campaignId);
        } catch (_) {}
      });

      // Create in-app event notification
      try {
        await NotificationService.createNotification({
          userId,
          title: 'Spotlight submission received',
          body: 'Your spotlight post has been submitted and is undergoing verification.',
          type: 'spotlight',
          actionUrl: '/spotlight',
        });
      } catch (_) {}

      return {
        success: true,
        campaignId,
        submissionStatus: 'pending',
        message: 'Spotlight submission received and is pending verification.',
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Records user participation (sharing to WhatsApp Status)
   */
  static async participate(userId: string, campaignId: string): Promise<{ success: boolean; message: string; pointsAwarded: number }> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const { rows: existing } = await client.query(
        `SELECT id FROM spotlight_participations WHERE campaign_id = $1 AND user_id = $2`,
        [campaignId, userId]
      );

      if (existing.length > 0) {
        await client.query('COMMIT');
        return { success: true, message: 'Participation already recorded.', pointsAwarded: 0 };
      }

      await client.query(`
        INSERT INTO spotlight_participations (campaign_id, user_id, channel, verified)
        VALUES ($1, $2, 'whatsapp_status', TRUE)
      `, [campaignId, userId]);

      await client.query(`
        INSERT INTO akawo_ledger (user_id, points_awarded, transaction_type, verified_by_bot)
        VALUES ($1, 2, 'spotlight_share', TRUE)
      `, [userId]);

      // Fetch campaign owner details to trigger participation batching notification (Section 7 & 8)
      const { rows: [camp] } = await client.query(`
        SELECT sc.user_id as target_user_id, u.full_name as actor_name
        FROM spotlight_campaigns sc
        JOIN users u ON u.id = $1
        WHERE sc.id = $2
      `, [userId, campaignId]);

      await client.query('COMMIT');

      if (camp) {
        setImmediate(async () => {
          try {
            await SpotlightNotificationService.recordParticipationAndBatch({
              targetUserId: camp.target_user_id,
              actorUserId: userId,
              actorName: camp.actor_name || 'A network member',
              campaignId,
            });
          } catch (_) {}
        });
      }

      return { success: true, message: 'Participation verified! +2 Akawo Points awarded.', pointsAwarded: 2 };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Fetches list of authorized participants for a campaign.
   */
  static async getCampaignParticipants(campaignId: string): Promise<SpotlightParticipant[]> {
    const { rows } = await pool.query(`
      SELECT 
        u.id, u.business_name, u.full_name, u.avatar_id,
        COALESCE(mn.name, 'Verified Member') as primary_offer,
        sp.created_at as participated_at
      FROM spotlight_participations sp
      JOIN users u ON u.id = sp.user_id
      LEFT JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
      LEFT JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      WHERE sp.campaign_id = $1 AND sp.verified = TRUE
      ORDER BY sp.created_at DESC
    `, [campaignId]);

    return rows.map(r => ({
      id: r.id,
      businessName: r.business_name || r.full_name,
      fullName: r.full_name || '',
      avatarId: r.avatar_id || 1,
      primaryOffer: r.primary_offer,
      participatedAt: r.participated_at,
    }));
  }

  /**
   * Fetches Spotlight History (Mine & Others)
   */
  static async getHistory(userId: string) {
    // 1. Mine (Campaigns created by the user)
    const { rows: mineCampaigns } = await pool.query(`
      SELECT 
        sc.id as campaign_id, sc.title, sc.promo_text, sc.caption, sc.flyer_url,
        sc.start_date, sc.end_date, sc.target_participants,
        COALESCE(sc.submission_status, 'verified') as submission_status,
        sc.rejection_reason,
        COUNT(sp.id) as participant_count
      FROM spotlight_campaigns sc
      LEFT JOIN spotlight_participations sp ON sp.campaign_id = sc.id
      WHERE sc.user_id = $1
      GROUP BY sc.id
      ORDER BY sc.start_date DESC
    `, [userId]);

    // 2. Others (Campaigns user shared for others)
    const { rows: othersParticipations } = await pool.query(`
      SELECT 
        sp.id as participation_id, sp.created_at as participated_at,
        sc.id as campaign_id, sc.title, sc.promo_text, sc.caption, sc.flyer_url,
        u.business_name as creator_business_name,
        u.full_name as creator_name,
        u.avatar_id as creator_avatar,
        COALESCE(mn.name, 'Business') as creator_primary_offer,
        (SELECT COUNT(*) FROM spotlight_participations WHERE campaign_id = sc.id) as total_participants
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
        submissionStatus: c.submission_status,
        rejectionReason: c.rejection_reason,
        participantCount: parseInt(c.participant_count, 10) || 0,
        targetParticipants: c.target_participants || 48,
      })),
      others: othersParticipations.map(p => ({
        participationId: p.participation_id,
        campaignId: p.campaign_id,
        participatedAt: p.participated_at,
        title: p.title,
        promoText: p.promo_text,
        caption: p.caption,
        flyerUrl: p.flyer_url,
        creatorBusinessName: p.creator_business_name,
        creatorName: p.creator_name,
        creatorAvatar: p.creator_avatar,
        creatorPrimaryOffer: p.creator_primary_offer,
        participantCount: parseInt(p.total_participants, 10) || 1,
      })),
    };
  }
  /**
   * Verifies a Spotlight submission (admin action).
   * Fires SPOTLIGHT_VERIFIED notification with real participant count.
   */
  static async verifySubmission(campaignId: string): Promise<{
    success: boolean;
    userId: string;
    participantCount: number;
  }> {
    const { rows: [campaign] } = await pool.query(`
      UPDATE spotlight_campaigns
      SET submission_status = 'verified', is_active = TRUE
      WHERE id = $1
      RETURNING user_id, id, end_date
    `, [campaignId]);

    if (!campaign) {
      throw new Error('Campaign not found');
    }

    const { rows: [{ count: partCount }] } = await pool.query(`
      SELECT COUNT(*) FROM spotlight_participations WHERE campaign_id = $1
    `, [campaignId]);

    const participantCount = parseInt(partCount, 10) || 0;

    // Fire SPOTLIGHT_VERIFIED notification with real participant count
    setImmediate(async () => {
      try {
        await NotificationEvents.spotlightVerified({
          userId: campaign.user_id,
          cycleId: campaignId,
          participantCount,
        });
      } catch (_) {}
    });

    return { success: true, userId: campaign.user_id, participantCount };
  }
}
