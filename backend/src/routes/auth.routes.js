"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_service_1 = require("../services/auth.service");
const router = (0, express_1.Router)();
router.post('/register', async (req, res) => {
    try {
        const { phoneNumber, fullName, nicheId } = req.body;
        if (!phoneNumber || !fullName || !nicheId) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        const result = await auth_service_1.AuthService.registerUser(phoneNumber, fullName, nicheId);
        res.status(201).json(result);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
router.post('/login', async (req, res) => {
    try {
        const { phoneNumber } = req.body;
        if (!phoneNumber) {
            return res.status(400).json({ error: 'Phone number required' });
        }
        const result = await auth_service_1.AuthService.loginUser(phoneNumber);
        res.json(result);
    }
    catch (error) {
        if (error.message === 'User not found') {
            return res.status(404).json({ error: error.message });
        }
        res.status(500).json({ error: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=auth.routes.js.map