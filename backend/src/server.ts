import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import cron from 'node-cron';

// Routes imports will go here
import authRoutes from './routes/auth.routes';
import usersRoutes from './routes/users.routes';
import pollsRoutes from './routes/polls.routes';
import matchesRoutes from './routes/matches.routes';
import botRoutes from './routes/bot.routes';
import adminRoutes from './routes/admin.routes';
import crmRoutes from './routes/crm.routes';
import taxonomyRoutes from './routes/taxonomy.routes';
import demandRoutes from './routes/demand.routes';
import interestRoutes from './routes/interest.routes';
import adminContentRoutes from './routes/admin_content.routes';
import matchingRoutes from './routes/matching.routes';
import spotlightRoutes from './routes/spotlight.routes';
import notificationsRoutes from './routes/notifications.routes';
import contactsRoutes from './routes/contacts.routes';
import { MatchingEngineService } from './services/matching/matching_engine.service';
import { DemandService } from './services/demand.service';
import { InterestStateService } from './services/interest_state.service';
import { RetentionService } from './services/retention.service';

dotenv.config();

const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// Routes Registration
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', usersRoutes);
app.use('/api/v1/polls', pollsRoutes);
app.use('/api/v1/matches', matchesRoutes);
app.use('/api/v1/bot', botRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/admin/content-engine', adminContentRoutes);
app.use('/api/v1/matching', matchingRoutes);
app.use('/api/v1/spotlight', spotlightRoutes);
app.use('/api/v1/notifications', notificationsRoutes);
app.use('/api/v1/contacts', contactsRoutes);
app.use('/api/v1/crm', crmRoutes);
app.use('/api/v1/taxonomy', taxonomyRoutes);
app.use('/api/v1/demand', demandRoutes);
app.use('/api/v1/interest', interestRoutes);

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// CRON: Run Interest State Recency Decay daily @ 03:00 UTC
cron.schedule('0 3 * * *', async () => {
  console.log('Running Interest Graph Recency Decay...');
  try {
    await InterestStateService.runRecencyDecay();
    console.log('Interest Graph Recency Decay complete.');
  } catch (err) {
    console.error('Interest Graph Recency Decay failed:', err);
  }
}, {
  timezone: "UTC"
});

// CRON Job: Run Weekly Matching Cycle Sunday @ 00:00 UTC
cron.schedule('0 0 * * 0', async () => {
  console.log('Initiating Weekly Matching Cycle...');
  try {
    const result = await MatchingEngineService.runWeeklyMatchingCycle();
    console.log('Weekly Matching Cycle Completed Successfully:', result);
  } catch (error) {
    console.error('Weekly Matching Cycle Failed:', error);
  }
}, {
  timezone: "UTC"
});

// CRON: Cleanup expired dynamic demand daily @ 02:00 UTC
cron.schedule('0 2 * * *', async () => {
  console.log('Cleaning up expired dynamic demand...');
  try {
    const result = await DemandService.cleanupExpiredDemand();
    console.log('Demand cleanup done:', result);
  } catch (error) {
    console.error('Demand cleanup failed:', error);
  }
}, {
  timezone: "UTC"
});

// CRON: Daily Retention Check @ 09:00 UTC
// Only sends notifications when there is REAL value waiting for the user.
cron.schedule('0 9 * * *', async () => {
  console.log('Running Daily Retention Check...');
  try {
    const result = await RetentionService.runDailyRetentionCheck();
    console.log('Retention Check complete:', result);
  } catch (error) {
    console.error('Retention Check failed:', error);
  }
}, {
  timezone: "UTC"
});

// Start Server
app.listen(port, () => {
  console.log(`BizSquare Backend Server running on port ${port}`);
});
