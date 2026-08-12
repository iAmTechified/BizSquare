import { pool } from '../../db/pool';
import { UserSupplyProfile } from '../../types/matching_engine.types';

export class SupplyProfileService {
  /**
   * Loads all active users' supply profiles (Primary Offer + Secondary Offers)
   */
  static async loadAllSupplyProfiles(): Promise<Map<string, UserSupplyProfile>> {
    const query = `
      SELECT 
        u.id as user_id,
        u.business_name,
        u.full_name,
        u.phone_number,
        u.avatar_id,
        bmn.micro_niche_id,
        bmn.is_primary,
        mn.name as niche_name,
        COALESCE(it.slug, mn.name) as niche_slug
      FROM users u
      JOIN business_micro_niches bmn ON bmn.user_id = u.id
      JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      LEFT JOIN interest_taxonomies it ON (it.slug = mn.name OR it.name ILIKE mn.name)
      WHERE u.is_active = TRUE AND u.onboarding_completed = TRUE
      ORDER BY u.id, bmn.is_primary DESC
    `;
    const { rows } = await pool.query(query);

    const profilesMap = new Map<string, UserSupplyProfile>();

    for (const row of rows) {
      let profile = profilesMap.get(row.user_id);
      if (!profile) {
        profile = {
          userId: row.user_id,
          businessName: row.business_name,
          fullName: row.full_name || undefined,
          phoneNumber: row.phone_number || undefined,
          avatarId: row.avatar_id || 1,
          primaryOfferId: '',
          primaryOfferName: '',
          primaryOfferSlug: '',
          secondaryOffers: [],
          secondaryOfferIds: [],
        };
        profilesMap.set(row.user_id, profile);
      }

      if (row.is_primary) {
        profile.primaryOfferId = row.micro_niche_id;
        profile.primaryOfferName = row.niche_name;
        profile.primaryOfferSlug = row.niche_slug;
      } else {
        profile.secondaryOffers.push({
          id: row.micro_niche_id,
          name: row.niche_name,
          slug: row.niche_slug,
        });
        profile.secondaryOfferIds.push(row.micro_niche_id);
      }
    }

    return profilesMap;
  }

  /**
   * Loads a single user's supply profile
   */
  static async getSupplyProfile(userId: string): Promise<UserSupplyProfile | null> {
    const all = await this.loadAllSupplyProfiles();
    return all.get(userId) || null;
  }
}
