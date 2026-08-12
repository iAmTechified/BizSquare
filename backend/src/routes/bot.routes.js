"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const botAuth_middleware_1 = require("../middleware/botAuth.middleware");
const pool_1 = require("../db/pool");
const router = (0, express_1.Router)();
// Apply the API key middleware to all bot routes
router.use(botAuth_middleware_1.verifyBotApiKey);
router.get('/spotlight/today', async (req, res) => {
    try {
        // Logic to fetch today's spotlight user.
        // For MVP, we can pick a user with high points or random.
        const { rows } = await pool_1.pool.query(`SELECT id, phone_number, full_name, akawo_points 
       FROM users 
       WHERE is_active = true 
       ORDER BY RANDOM() 
       LIMIT 1`);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'No active users found' });
        }
        res.json({ spotlight_user: rows[0] });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
router.post('/verify-mention', async (req, res) => {
    try {
        const { phoneNumber } = req.body;
        if (!phoneNumber) {
            return res.status(400).json({ error: 'Missing phoneNumber' });
        }
        // Find the user by phone number
        const { rows: users } = await pool_1.pool.query(`SELECT id FROM users WHERE phone_number = $1`, [phoneNumber]);
        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found for that phone number' });
        }
        const userId = users[0].id;
        // Idempotency Check: Prevent duplicate verifications on the same day
        const { rows: existingLedger } = await pool_1.pool.query(`SELECT id FROM akawo_ledger 
       WHERE user_id = $1 
         AND transaction_type = 'status_mention' 
         AND DATE(created_at) = CURRENT_DATE`, [userId]);
        if (existingLedger.length > 0) {
            return res.status(409).json({ error: 'User already awarded points today for status mention' });
        }
        // Award Points
        const pointsToAward = 10;
        const { rows: ledgerEntry } = await pool_1.pool.query(`INSERT INTO akawo_ledger (user_id, points_awarded, transaction_type, verified_by_bot)
       VALUES ($1, $2, 'status_mention', true)
       RETURNING *`, [userId, pointsToAward]);
        res.json({
            success: true,
            message: `Awarded ${pointsToAward} points to user`,
            ledger_entry: ledgerEntry[0]
        });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=bot.routes.js.map