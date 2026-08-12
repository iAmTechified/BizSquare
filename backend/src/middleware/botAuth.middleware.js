"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyBotApiKey = void 0;
const express_1 = require("express");
const verifyBotApiKey = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    const validApiKey = process.env.BOT_API_KEY;
    if (!validApiKey) {
        console.warn('BOT_API_KEY environment variable is not set!');
        return res.status(500).json({ error: 'Internal server configuration error.' });
    }
    if (apiKey === validApiKey) {
        next();
    }
    else {
        res.status(403).json({ error: 'Forbidden. Invalid bot API key.' });
    }
};
exports.verifyBotApiKey = verifyBotApiKey;
//# sourceMappingURL=botAuth.middleware.js.map