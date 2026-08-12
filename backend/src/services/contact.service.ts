import { pool } from '../db/pool';

export interface SquareContactDto {
  id: string;
  userId?: string | undefined;
  businessName: string;
  fullName: string;
  phoneNumber: string;
  avatarId: number;
  primaryOffer: string;
  secondaryOffers: string[];
  isSquareContact: boolean;
  isStarred: boolean;
  isArchived: boolean;
  labels: string[];
  notes?: string | undefined;
  gainedDate: string;
  matchReason: string;
  tier: string;
  isMutual: boolean;
  syncStatus: string;
}

export class ContactService {
  /**
   * Fetches all Square Contacts for a user
   */
  static async getUserContacts(userId: string, includeArchived = false): Promise<SquareContactDto[]> {
    const { rows } = await pool.query(`
      SELECT 
        uc.id,
        uc.owner_id,
        uc.contact_user_id,
        uc.external_name,
        uc.external_phone,
        uc.is_starred,
        uc.is_archived,
        uc.notes,
        uc.created_at as gained_date,
        u.id as matched_user_id,
        u.business_name,
        u.full_name,
        u.phone_number,
        u.avatar_id,
        COALESCE(mn.name, 'Verified Business') as primary_offer,
        ma.match_reason,
        ma.tier,
        ma.is_mutual,
        COALESCE(cr.sync_status, 'SYNCED') as sync_status,
        ARRAY_AGG(cl.name) FILTER (WHERE cl.name IS NOT NULL) as labels
      FROM user_contacts uc
      LEFT JOIN users u ON u.id = uc.contact_user_id
      LEFT JOIN business_micro_niches bmn ON bmn.user_id = u.id AND bmn.is_primary = TRUE
      LEFT JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
      LEFT JOIN match_allocations ma ON ma.user_id = uc.owner_id AND ma.candidate_user_id = uc.contact_user_id
      LEFT JOIN contact_relationships cr ON (
        (cr.user_a_id = uc.owner_id AND cr.user_b_id = uc.contact_user_id) OR
        (cr.user_b_id = uc.owner_id AND cr.user_a_id = uc.contact_user_id)
      )
      LEFT JOIN contact_label_assignments cla ON cla.contact_id = uc.id
      LEFT JOIN contact_labels cl ON cl.id = cla.label_id
      WHERE uc.owner_id = $1 ${includeArchived ? '' : 'AND uc.is_archived = FALSE'}
      GROUP BY uc.id, u.id, mn.name, ma.match_reason, ma.tier, ma.is_mutual, cr.sync_status
      ORDER BY uc.created_at DESC
    `, [userId]);

    return rows.map(r => ({
      id: r.id,
      userId: r.matched_user_id || undefined,
      businessName: r.business_name || r.external_name || 'Verified Business',
      fullName: r.full_name || r.external_name || 'Partner',
      phoneNumber: r.phone_number || r.external_phone || '',
      avatarId: r.avatar_id || 1,
      primaryOffer: r.primary_offer,
      secondaryOffers: [],
      isSquareContact: r.contact_user_id != null,
      isStarred: Boolean(r.is_starred),
      isArchived: Boolean(r.is_archived),
      labels: r.labels || [],
      notes: r.notes || undefined,
      gainedDate: r.gained_date.toISOString(),
      matchReason: r.match_reason || 'WEEKLY_CONTACT_GAIN',
      tier: r.tier || 'TIER_1',
      isMutual: Boolean(r.is_mutual),
      syncStatus: r.sync_status || 'SYNCED',
    }));
  }

  /**
   * Updates contact fields (star, archive, notes, label)
   */
  static async updateContact(
    userId: string,
    contactId: string,
    params: { isStarred?: boolean | undefined; isArchived?: boolean | undefined; notes?: string | undefined; labels?: string[] | undefined }
  ): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(`
        UPDATE user_contacts
        SET 
          is_starred = COALESCE($1, is_starred),
          is_archived = COALESCE($2, is_archived),
          notes = COALESCE($3, notes)
        WHERE id = $4 AND owner_id = $5
      `, [params.isStarred, params.isArchived, params.notes, contactId, userId]);

      if (params.labels !== undefined) {
        // Clear previous label assignments
        await client.query(`DELETE FROM contact_label_assignments WHERE contact_id = $1`, [contactId]);

        for (const labelName of params.labels) {
          // Upsert label for this user
          const { rows: [label] } = await client.query(`
            INSERT INTO contact_labels (user_id, name)
            VALUES ($1, $2)
            ON CONFLICT (user_id, name) DO UPDATE SET name = EXCLUDED.name
            RETURNING id
          `, [userId, labelName.trim()]);

          if (label) {
            await client.query(`
              INSERT INTO contact_label_assignments (contact_id, label_id)
              VALUES ($1, $2)
              ON CONFLICT DO NOTHING
            `, [contactId, label.id]);
          }
        }
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Bulk updates multiple contacts (star, archive, restore, delete, assign labels)
   */
  static async bulkUpdate(
    userId: string,
    contactIds: string[],
    action: 'star' | 'unstar' | 'archive' | 'restore' | 'delete' | 'assign_label',
    labelName?: string
  ): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      switch (action) {
        case 'star':
          await client.query(`UPDATE user_contacts SET is_starred = TRUE WHERE owner_id = $1 AND id = ANY($2)`, [userId, contactIds]);
          break;
        case 'unstar':
          await client.query(`UPDATE user_contacts SET is_starred = FALSE WHERE owner_id = $1 AND id = ANY($2)`, [userId, contactIds]);
          break;
        case 'archive':
          await client.query(`UPDATE user_contacts SET is_archived = TRUE WHERE owner_id = $1 AND id = ANY($2)`, [userId, contactIds]);
          break;
        case 'restore':
          await client.query(`UPDATE user_contacts SET is_archived = FALSE WHERE owner_id = $1 AND id = ANY($2)`, [userId, contactIds]);
          break;
        case 'delete':
          await client.query(`DELETE FROM user_contacts WHERE owner_id = $1 AND id = ANY($2)`, [userId, contactIds]);
          break;
        case 'assign_label':
          if (labelName) {
            const { rows: [label] } = await client.query(`
              INSERT INTO contact_labels (user_id, name)
              VALUES ($1, $2)
              ON CONFLICT (user_id, name) DO UPDATE SET name = EXCLUDED.name
              RETURNING id
            `, [userId, labelName.trim()]);

            for (const cId of contactIds) {
              await client.query(`
                INSERT INTO contact_label_assignments (contact_id, label_id)
                VALUES ($1, $2)
                ON CONFLICT DO NOTHING
              `, [cId, label.id]);
            }
          }
          break;
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Merges two duplicate contacts preserving all labels, notes, and Square metadata
   */
  static async mergeContacts(
    userId: string,
    primaryContactId: string,
    duplicateContactId: string
  ): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Fetch duplicate notes and labels
      const { rows: [dup] } = await client.query(
        `SELECT * FROM user_contacts WHERE id = $1 AND owner_id = $2`,
        [duplicateContactId, userId]
      );

      if (dup) {
        // Transfer label assignments to primary contact
        await client.query(`
          UPDATE contact_label_assignments
          SET contact_id = $1
          WHERE contact_id = $2
          ON CONFLICT DO NOTHING
        `, [primaryContactId, duplicateContactId]);

        // Append notes if duplicate has extra notes
        if (dup.notes) {
          await client.query(`
            UPDATE user_contacts
            SET notes = CASE 
              WHEN notes IS NULL OR notes = '' THEN $1
              ELSE notes || E'\n' || $1
            END
            WHERE id = $2 AND owner_id = $3
          `, [dup.notes, primaryContactId, userId]);
        }

        // Delete duplicate contact record
        await client.query(`DELETE FROM user_contacts WHERE id = $1 AND owner_id = $2`, [duplicateContactId, userId]);
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Custom Label Management
   */
  static async getLabels(userId: string): Promise<{ id: string; name: string; color: string; count: number }[]> {
    const { rows } = await pool.query(`
      SELECT cl.id, cl.name, cl.color, COUNT(cla.contact_id) as count
      FROM contact_labels cl
      LEFT JOIN contact_label_assignments cla ON cla.label_id = cl.id
      WHERE cl.user_id = $1
      GROUP BY cl.id
      ORDER BY cl.name ASC
    `, [userId]);

    return rows.map(r => ({
      id: r.id,
      name: r.name,
      color: r.color || '#0058FF',
      count: parseInt(r.count, 10) || 0,
    }));
  }

  static async createLabel(userId: string, name: string, color = '#0058FF'): Promise<{ id: string; name: string; color: string }> {
    const { rows: [label] } = await pool.query(`
      INSERT INTO contact_labels (user_id, name, color)
      VALUES ($1, $2, $3)
      ON CONFLICT (user_id, name) DO UPDATE SET color = EXCLUDED.color
      RETURNING id, name, color
    `, [userId, name.trim(), color]);
    return label;
  }

  static async deleteLabel(userId: string, labelId: string): Promise<void> {
    // Deleting a label cascades assignments, but preserves contact records
    await pool.query(`DELETE FROM contact_labels WHERE id = $1 AND user_id = $2`, [labelId, userId]);
  }

  /**
   * Device synchronization acknowledgment
   */
  static async acknowledgeDeviceSync(userId: string, contactUserIds: string[], status: 'SYNCED' | 'FAILED'): Promise<void> {
    if (contactUserIds.length === 0) return;
    await pool.query(`
      UPDATE contact_relationships
      SET sync_status = $1, last_synced_at = CURRENT_TIMESTAMP
      WHERE (user_a_id = $2 AND user_b_id = ANY($3))
         OR (user_b_id = $2 AND user_a_id = ANY($3))
    `, [status, userId, contactUserIds]);
  }
}
