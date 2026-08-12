import { Router, Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';
import { pool } from '../db/pool';

const router = Router();

/**
 * POST /api/v1/auth/verify-and-register
 * POST /api/v1/auth/verify-code (Alias)
 * Step 3: Atomic verification + account creation.
 * This is the FIRST backend write during onboarding.
 */
const handleVerifyAndRegister = async (req: Request, res: Response) => {
  try {
    const { code, phoneNumber, businessName, fullName, avatarId, microNicheIds, primaryMicroNicheId } = req.body;

    if (!code || !phoneNumber || !businessName || !microNicheIds || !primaryMicroNicheId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await AuthService.verifyAndRegister(
      code,
      phoneNumber,
      businessName,
      fullName || businessName,
      avatarId || 1,
      microNicheIds,
      primaryMicroNicheId
    );

    res.status(201).json(result);
  } catch (error: any) {
    const errorMap: Record<string, { status: number; message: string }> = {
      'INVALID_CODE': { status: 400, message: 'Invalid verification code' },
      'CODE_ALREADY_USED': { status: 400, message: 'This code has already been used' },
      'CODE_EXPIRED': { status: 400, message: 'Verification code has expired' },
      'PHONE_ALREADY_REGISTERED': { status: 409, message: 'This phone number is already registered' },
      'INVALID_MICRO_NICHES': { status: 400, message: 'One or more selected niches are invalid' },
    };

    const mapped = errorMap[error.message];
    if (mapped) {
      return res.status(mapped.status).json({ error: mapped.message, code: error.message });
    }

    res.status(500).json({ error: error.message });
  }
};

router.post('/verify-and-register', handleVerifyAndRegister);
router.post('/verify-code', handleVerifyAndRegister);

/**
 * POST /api/v1/auth/validate-setup-code
 * Real-time setup code validation endpoint for mobile app onboarding flow.
 * Validates setup code against authoritative PostgreSQL database state.
 * Returns explicit status contract: AVAILABLE, INVALID, EXPIRED, USED, REVOKED.
 */
router.post('/validate-setup-code', async (req: Request, res: Response) => {
  try {
    const rawCode = req.body.code;
    if (!rawCode || typeof rawCode !== 'string' || !rawCode.trim()) {
      return res.status(400).json({
        valid: false,
        status: 'INVALID',
        message: "Please enter a valid setup code.",
      });
    }

    const normalizedCode = rawCode.trim().toUpperCase();
    const DEV_SETUP_CODE = 'B41230';

    if (normalizedCode === DEV_SETUP_CODE) {
      return res.json({
        valid: true,
        status: 'AVAILABLE',
        message: 'Developer setup code accepted.',
      });
    }

    const { rows } = await pool.query(
      `SELECT id, code, is_used, is_revoked, expires_at, intended_user_id 
       FROM verification_codes 
       WHERE code = $1`,
      [normalizedCode]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        valid: false,
        status: 'INVALID',
        message: "That setup code isn't valid.",
      });
    }

    const vCode = rows[0];

    if (vCode.is_revoked) {
      return res.status(400).json({
        valid: false,
        status: 'REVOKED',
        message: 'That setup code is no longer active.',
      });
    }

    if (vCode.is_used) {
      return res.status(400).json({
        valid: false,
        status: 'USED',
        message: 'That setup code has already been used.',
      });
    }

    if (new Date(vCode.expires_at) <= new Date()) {
      return res.status(400).json({
        valid: false,
        status: 'EXPIRED',
        message: 'That setup code has expired. Please request a new one.',
      });
    }

    res.json({
      valid: true,
      status: 'AVAILABLE',
      message: 'Setup code is valid.',
      code: vCode.code,
      expires_at: vCode.expires_at,
    });
  } catch (error: any) {
    console.error('Error validating setup code:', error);
    res.status(500).json({
      valid: false,
      status: 'SERVER_ERROR',
      message: 'We couldn\'t verify your code. Check your connection and try again.',
    });
  }
});

/**
 * POST /api/v1/auth/complete-onboarding
 * Steps 4+5: Security PIN + Username + Interests.
 */
router.post('/complete-onboarding', authenticateJWT, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user.id;
    const { username, pin, interestMicroNicheIds } = req.body;

    if (!username || !pin) {
      return res.status(400).json({ error: 'Username and PIN are required' });
    }

    const result = await AuthService.completeOnboarding(
      userId,
      username,
      pin,
      interestMicroNicheIds || []
    );

    res.json(result);
  } catch (error: any) {
    const errorMap: Record<string, { status: number; message: string }> = {
      'USERNAME_TAKEN': { status: 409, message: 'Username is already taken' },
      'USERNAME_INVALID_LENGTH': { status: 400, message: 'Username must be 3-30 characters' },
      'USERNAME_INVALID_CHARS': { status: 400, message: 'Username can only contain letters, numbers, and underscores' },
      'INTEREST_OVERLAPS_OWN_SUPPLY': { status: 400, message: 'Cannot select your own business niche as an interest' },
    };

    const mapped = errorMap[error.message];
    if (mapped) {
      return res.status(mapped.status).json({ error: mapped.message, code: error.message });
    }

    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/v1/auth/login
 * Phone + PIN authentication.
 */
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { phoneNumber, pin } = req.body;
    if (!phoneNumber) {
      return res.status(400).json({ error: 'Phone number required' });
    }
    const result = await AuthService.loginUser(phoneNumber, pin);
    res.json(result);
  } catch (error: any) {
    if (error.message === 'User not found') {
      return res.status(404).json({ error: error.message });
    }
    if (error.message === 'INVALID_PIN') {
      return res.status(401).json({ error: 'Incorrect PIN', code: 'INVALID_PIN' });
    }
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/v1/auth/username-available/:username
 * Real-time username availability check.
 */
router.get('/username-available/:username', async (req: Request, res: Response) => {
  try {
    const username = req.params.username as string;
    if (!username) {
      return res.status(400).json({ error: 'Username required' });
    }
    const available = await AuthService.checkUsernameAvailability(username);
    res.json({ username, available });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
