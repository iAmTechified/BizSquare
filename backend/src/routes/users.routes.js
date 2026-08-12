"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middleware_1 = require("../middleware/auth.middleware");
const pool_1 = require("../db/pool");
const router = (0, express_1.Router)();
router.get('/me', auth_middleware_1.authenticateJWT, async (req, res) => {
    try {
        const userId = req.user.id;
        const { rows } = await pool_1.pool.query(`SELECT id, phone_number, full_name, niche_id, akawo_points, is_active, created_at 
       FROM users 
       WHERE id = $1`, [userId]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({ user: rows[0] });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=users.routes.js.map