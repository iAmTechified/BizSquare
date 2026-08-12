import { Router, Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { authenticateJWT, AuthRequest } from '../middleware/auth.middleware';

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
