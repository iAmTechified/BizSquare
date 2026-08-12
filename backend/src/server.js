"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const node_cron_1 = __importDefault(require("node-cron"));
// Routes imports will go here
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const users_routes_1 = __importDefault(require("./routes/users.routes"));
const polls_routes_1 = __importDefault(require("./routes/polls.routes"));
const matches_routes_1 = __importDefault(require("./routes/matches.routes"));
const bot_routes_1 = __importDefault(require("./routes/bot.routes"));
const matchmaking_service_1 = require("./services/matchmaking.service");
dotenv_1.default.config();
const app = (0, express_1.default)();
const port = process.env.PORT || 8080;
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Routes Registration
app.use('/api/v1/auth', auth_routes_1.default);
app.use('/api/v1/users', users_routes_1.default);
app.use('/api/v1/polls', polls_routes_1.default);
app.use('/api/v1/matches', matches_routes_1.default);
app.use('/api/v1/bot', bot_routes_1.default);
// Health Check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});
// CRON Job Initialization: Run Sunday @ 00:00 UTC
node_cron_1.default.schedule('0 0 * * 0', async () => {
    console.log('Initiating Weekly Matchmaking Batch...');
    try {
        const result = await matchmaking_service_1.MatchmakingService.runWeeklyMatchmaking();
        console.log('Matchmaking Batch Completed Successfully:', result);
    }
    catch (error) {
        console.error('Matchmaking Batch Failed:', error);
    }
}, {
    scheduled: true,
    timezone: "UTC"
});
// Start Server
app.listen(port, () => {
    console.log(`Akawo Backend Server running on port ${port}`);
});
//# sourceMappingURL=server.js.map