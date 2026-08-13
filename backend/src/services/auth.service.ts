import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { pool } from '../db/pool';

export class AuthService {
  /**
   * Step 3: Atomic verify-and-register.
   * Validates verification code, then creates user + business_micro_niches in a single transaction.
   * This is the FIRST permanent backend write during onboarding.
   */
  static async verifyAndRegister(
    code: string,
    phoneNumber: string,
    businessName: string,
    fullName: string,
    avatarId: number,
    microNicheIds: string[],
    primaryMicroNicheId: string
  ) {
    if (!code || !phoneNumber || !businessName || !microNicheIds.length) {
      throw new Error('Missing required fields');
    }

    if (microNicheIds.length > 3) {
      throw new Error('Maximum 3 micro-niches allowed');
    }

    if (!microNicheIds.includes(primaryMicroNicheId)) {
      throw new Error('Primary micro-niche must be one of the selected niches');
    }

    // Check for duplicates in selected micro-niches
    const uniqueNiches = new Set(microNicheIds);
    if (uniqueNiches.size !== microNicheIds.length) {
      throw new Error('Duplicate micro-niches are not allowed');
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Validate verification code
      const DEV_SETUP_CODE = 'B41230';
      const isDevCode = code.trim().toUpperCase() === DEV_SETUP_CODE;
      let vCodeId: string | null = null;

      if (!isDevCode) {
        const { rows: codeRows } = await client.query(
          `SELECT id, is_used, is_revoked, expires_at, intended_user_id FROM verification_codes WHERE code = $1`,
          [code.trim().toUpperCase()]
        );

        if (codeRows.length === 0) {
          throw new Error('INVALID_CODE');
        }

        const vCode = codeRows[0];

        if (vCode.is_revoked) {
          throw new Error('CODE_REVOKED');
        }

        if (vCode.is_used) {
          throw new Error('CODE_ALREADY_USED');
        }

        if (new Date(vCode.expires_at) < new Date()) {
          throw new Error('CODE_EXPIRED');
        }

        vCodeId = vCode.id;
      }

      // 2. Check phone number not already registered
      const { rows: existingUser } = await client.query(
        `SELECT id FROM users WHERE phone_number = $1`,
        [phoneNumber]
      );

      if (existingUser.length > 0) {
        throw new Error('PHONE_ALREADY_REGISTERED');
      }

      // 3. Validate micro-niche IDs exist and are active
      const placeholders = microNicheIds.map((_, i) => `$${i + 1}`).join(', ');
      const { rows: validNiches } = await client.query(
        `SELECT id FROM micro_niches WHERE id IN (${placeholders}) AND is_active = true`,
        microNicheIds
      );

      if (validNiches.length !== microNicheIds.length) {
        throw new Error('INVALID_MICRO_NICHES');
      }

      // 4. Create user
      const { rows: userRows } = await client.query(
        `INSERT INTO users (phone_number, full_name, business_name, avatar_id, verification_status, onboarding_completed)
         VALUES ($1, $2, $3, $4, 'verified', FALSE)
         RETURNING *`,
        [phoneNumber, fullName || businessName, businessName, avatarId]
      );

      const user = userRows[0];

      // 5. Create business_micro_niches
      for (const nicheId of microNicheIds) {
        await client.query(
          `INSERT INTO business_micro_niches (user_id, micro_niche_id, is_primary)
           VALUES ($1, $2, $3)`,
          [user.id, nicheId, nicheId === primaryMicroNicheId]
        );
      }

      // 6. Mark verification code as used if not universal dev code
      if (vCodeId) {
        await client.query(
          `UPDATE verification_codes SET is_used = TRUE, used_by = $1, used_at = CURRENT_TIMESTAMP WHERE id = $2`,
          [user.id, vCodeId]
        );
      }

      await client.query('COMMIT');

      const token = this.generateToken(user.id);
      return { user, token };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Steps 4+5: Complete onboarding (security + username + interests).
   * Called after successful verification.
   */
  static async completeOnboarding(
    userId: string,
    username: string,
    pin: string,
    interestMicroNicheIds: string[]
  ) {
    if (!username || !pin) {
      throw new Error('Username and PIN are required');
    }

    if (interestMicroNicheIds.length > 5) {
      throw new Error('Maximum 5 interests allowed');
    }

    // Validate username format
    const cleanUsername = username.startsWith('@') ? username.substring(1) : username;
    if (cleanUsername.length < 3 || cleanUsername.length > 30) {
      throw new Error('USERNAME_INVALID_LENGTH');
    }
    if (!/^[a-zA-Z0-9_]+$/.test(cleanUsername)) {
      throw new Error('USERNAME_INVALID_CHARS');
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Check username availability
      const { rows: existing } = await client.query(
        `SELECT id FROM users WHERE username = $1 AND id != $2`,
        [cleanUsername, userId]
      );

      if (existing.length > 0) {
        throw new Error('USERNAME_TAKEN');
      }

      // 2. Anti-echo-chamber: ensure interests don't overlap with user's own supply
      if (interestMicroNicheIds.length > 0) {
        const { rows: ownNiches } = await client.query(
          `SELECT micro_niche_id FROM business_micro_niches WHERE user_id = $1`,
          [userId]
        );
        const ownNicheSet = new Set(ownNiches.map((r: any) => r.micro_niche_id));

        for (const interestId of interestMicroNicheIds) {
          if (ownNicheSet.has(interestId)) {
            throw new Error('INTEREST_OVERLAPS_OWN_SUPPLY');
          }
        }
      }

      // 3. Hash PIN
      const pinHash = await bcrypt.hash(pin, 10);

      // 4. Update user
      await client.query(
        `UPDATE users SET username = $1, pin_hash = $2, onboarding_completed = TRUE
         WHERE id = $3`,
        [cleanUsername, pinHash, userId]
      );

      // 5. Create baseline demand
      if (interestMicroNicheIds.length > 0) {
        const values = interestMicroNicheIds
          .map((_, i) => `($1, $${i + 2}, 'onboarding', TRUE)`)
          .join(', ');
        await client.query(
          `INSERT INTO baseline_demand (user_id, micro_niche_id, source, is_active) VALUES ${values}
           ON CONFLICT (user_id, micro_niche_id) DO UPDATE SET is_active = TRUE`,
          [userId, ...interestMicroNicheIds]
        );
      }

      await client.query('COMMIT');
      return { success: true, username: cleanUsername };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Login with phone + PIN.
   */
  static async loginUser(phoneNumber: string, pin?: string) {
    const digits = phoneNumber.replace(/\D/g, '');
    const last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;

    const { rows } = await pool.query(
      `SELECT * FROM users 
       WHERE phone_number = $1 
          OR phone_number = $2
          OR RIGHT(REGEXP_REPLACE(phone_number, '\\D', '', 'g'), 10) = $3`,
      [phoneNumber, `+${digits}`, last10]
    );

    if (rows.length === 0) {
      throw new Error('User not found');
    }

    const user = rows[0];

    // Verify PIN if provided and user has one set
    if (pin && user.pin_hash) {
      const pinValid = await bcrypt.compare(pin, user.pin_hash);
      if (!pinValid) {
        throw new Error('INVALID_PIN');
      }
    }

    // Update last_login
    await pool.query(
      `UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1`,
      [user.id]
    );

    const token = this.generateToken(user.id);

    // Get user's supply micro-niches
    const { rows: supplyNiches } = await pool.query(
      `SELECT bmn.micro_niche_id, bmn.is_primary, mn.name
       FROM business_micro_niches bmn
       JOIN micro_niches mn ON mn.id = bmn.micro_niche_id
       WHERE bmn.user_id = $1`,
      [user.id]
    );

    // Get user's baseline demand
    const { rows: baselineDemand } = await pool.query(
      `SELECT bd.micro_niche_id, mn.name
       FROM baseline_demand bd
       JOIN micro_niches mn ON mn.id = bd.micro_niche_id
       WHERE bd.user_id = $1 AND bd.is_active = TRUE`,
      [user.id]
    );

    return {
      user: {
        id: user.id,
        phone_number: user.phone_number,
        full_name: user.full_name,
        business_name: user.business_name,
        username: user.username,
        avatar_id: user.avatar_id,
        akawo_points: user.akawo_points,
        onboarding_completed: user.onboarding_completed,
        verification_status: user.verification_status,
      },
      supplyNiches,
      baselineDemand,
      token,
    };
  }

  /**
   * Check username availability (real-time).
   */
  static async checkUsernameAvailability(username: string): Promise<boolean> {
    const clean = username.startsWith('@') ? username.substring(1) : username;

    // Reserved usernames
    const reserved = ['admin', 'bizsquare', 'support', 'help', 'system', 'mod', 'moderator'];
    if (reserved.includes(clean.toLowerCase())) return false;

    if (clean.length < 3 || !/^[a-zA-Z0-9_]+$/.test(clean)) return false;

    const { rows } = await pool.query(
      `SELECT id FROM users WHERE username = $1`,
      [clean]
    );
    return rows.length === 0;
  }

  private static generateToken(userId: string) {
    return jwt.sign({ id: userId }, process.env.JWT_SECRET as string, { expiresIn: '30d' });
  }
}
