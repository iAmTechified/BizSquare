"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middleware_1 = require("../middleware/auth.middleware");
const polls_service_1 = require("../services/polls.service");
const router = (0, express_1.Router)();
router.get('/active', auth_middleware_1.authenticateJWT, async (req, res) => {
    try {
        const polls = await polls_service_1.PollsService.getActivePolls(req.user.id);
        res.json({ polls });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
router.post('/swipe', auth_middleware_1.authenticateJWT, async (req, res) => {
    try {
        const { pollId, response } = req.body;
        if (pollId === undefined || response === undefined) {
            return res.status(400).json({ error: 'Missing pollId or response boolean' });
        }
        const result = await polls_service_1.PollsService.submitSwipe(req.user.id, pollId, response);
        res.json({ success: true, swipe: result });
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=polls.routes.js.map