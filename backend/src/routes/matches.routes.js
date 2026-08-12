"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middleware_1 = require("../middleware/auth.middleware");
const pool_1 = require("../db/pool");
const router = (0, express_1.Router)();
router.get('/current', auth_middleware_1.authenticateJWT, async (req, res) => {
    try {
        const userId = req.user.id;
        // Get matches where the user is either A or B for the most recent batch
        const { rows } = await pool_1.pool.query(`SELECT m.*, 
        CASE 
          WHEN m.user_a_id = $1 THEN row_to_json(ub)
          ELSE row_to_json(ua)
        END as matched_user
       FROM matches m
       JOIN users ua ON m.user_a_id = ua.id
       JOIN users ub ON m.user_b_id = ub.id
       WHERE (m.user_a_id = $1 OR m.user_b_id = $1)
       ORDER BY m.batch_date DESC
       LIMIT 100`, // Assuming maximum cap is never crazy high
        [userId]);
        res.json({ matches: rows });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
router.post('/sync-status', auth_middleware_1.authenticateJWT, async (req, res) => {
    try {
        const { matchId, status } = req.body; // e.g., 'synced'
        if (!matchId || !status) {
            return res.status(400).json({ error: 'Missing matchId or status' });
        }
        const { rows } = await pool_1.pool.query(`UPDATE matches 
       SET status = $1 
       WHERE id = $2 AND (user_a_id = $3 OR user_b_id = $3) 
       RETURNING *`, [status, matchId, req.user.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Match not found or unauthorized' });
        }
        res.json({ success: true, match: rows[0] });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=matches.routes.js.map