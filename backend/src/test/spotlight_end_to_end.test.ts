import { pool } from '../db/pool';
import { SpotlightService } from '../services/spotlight.service';

async function runSpotlightTests() {
  console.log('=== Starting Spotlight End-to-End Test Suite ===');
  const client = await pool.connect();
  let testUserId = '';
  let testPartnerId = '';
  let testCampaignId = '';

  try {
    // 1. Create 2 test users
    const rand = Math.floor(100000 + Math.random() * 900000);
    const { rows: [userA] } = await client.query(`
      INSERT INTO users (phone_number, full_name, business_name, avatar_id, onboarding_completed)
      VALUES ($1, 'Spotlight Test User A', 'Alpha Boutique', 1, TRUE)
      RETURNING id
    `, [`+23480${rand}1`]);
    testUserId = userA.id;

    const { rows: [userB] } = await client.query(`
      INSERT INTO users (phone_number, full_name, business_name, avatar_id, onboarding_completed)
      VALUES ($1, 'Spotlight Test User B', 'Beta Tech Hub', 2, TRUE)
      RETURNING id
    `, [`+23480${rand}2`]);
    testPartnerId = userB.id;
    console.log('✔ 1. Test users created');

    // 2. Fetch current spotlight for User A (Not My Turn initially)
    const currentA = await SpotlightService.getCurrentSpotlight(testUserId);
    console.log(`✔ 2. Initial Spotlight retrieved: isMyTurn = ${currentA.isMyTurn}, target = ${currentA.targetParticipants}`);

    // 3. User A submits a Spotlight campaign (Idempotent submission)
    const idempotencyKey = `idemp-${Date.now()}`;
    const submitResult1 = await SpotlightService.submitSpotlight(testUserId, {
      idempotencyKey,
      title: 'Alpha Boutique Flash Sale',
      promoText: '50% off all shoes and handbags this weekend!',
      caption: '#AlphaBoutique #BizSquare',
      flyerUrl: 'https://cdn.bizsquare.app/flyer-sample.jpg',
    });
    testCampaignId = submitResult1.campaignId;
    if (!submitResult1.success || submitResult1.submissionStatus !== 'pending') {
      throw new Error(`Submit failed: ${JSON.stringify(submitResult1)}`);
    }
    console.log('✔ 3. User A Spotlight submitted successfully (Pending verification)');

    // 4. Duplicate submission check with same idempotency key
    const submitResult2 = await SpotlightService.submitSpotlight(testUserId, {
      idempotencyKey,
      title: 'Alpha Boutique Flash Sale (Duplicate attempt)',
      promoText: 'Should return original response',
      caption: 'Duplicate',
    });
    if (submitResult2.campaignId !== testCampaignId) {
      throw new Error('Idempotency check failed: Returned different campaignId');
    }
    console.log('✔ 4. Duplicate submission protected by Idempotency Key');

    // 5. User B participates by sharing User A's campaign
    const partResult = await SpotlightService.participate(testPartnerId, testCampaignId);
    if (!partResult.success || partResult.pointsAwarded !== 2) {
      throw new Error(`Participation failed: ${JSON.stringify(partResult)}`);
    }
    console.log('✔ 5. User B participated and earned +2 points');

    // 6. Duplicate participation check
    const partDup = await SpotlightService.participate(testPartnerId, testCampaignId);
    if (partDup.pointsAwarded !== 0) {
      throw new Error('Duplicate participation did not prevent double points');
    }
    console.log('✔ 6. Duplicate participation safely prevented');

    // 7. Get participants list
    const participants = await SpotlightService.getCampaignParticipants(testCampaignId);
    if (participants.length !== 1 || participants[0].id !== testPartnerId) {
      throw new Error(`Participants mismatch: ${JSON.stringify(participants)}`);
    }
    console.log(`✔ 7. Campaign participants retrieved: ${participants[0].businessName}`);

    // 8. Get history for User A (Mine) and User B (Others)
    const histA = await SpotlightService.getHistory(testUserId);
    if (histA.mine.length === 0) {
      throw new Error('Mine history empty for User A');
    }
    const histB = await SpotlightService.getHistory(testPartnerId);
    if (histB.others.length === 0) {
      throw new Error('Others history empty for User B');
    }
    console.log(`✔ 8. Spotlight History retrieved: User A Mine = ${histA.mine.length}, User B Others = ${histB.others.length}`);

    console.log('🎉 ALL BACKEND SPOTLIGHT TESTS PASSED CLEANLY!');
  } catch (err) {
    console.error('❌ Test failed:', err);
    process.exit(1);
  } finally {
    // Cleanup
    if (testCampaignId) {
      await client.query(`DELETE FROM spotlight_participations WHERE campaign_id = $1`, [testCampaignId]);
      await client.query(`DELETE FROM spotlight_campaigns WHERE id = $1`, [testCampaignId]);
    }
    if (testUserId) {
      await client.query(`DELETE FROM akawo_ledger WHERE user_id = $1`, [testUserId]);
      await client.query(`DELETE FROM users WHERE id = $1`, [testUserId]);
    }
    if (testPartnerId) {
      await client.query(`DELETE FROM akawo_ledger WHERE user_id = $1`, [testPartnerId]);
      await client.query(`DELETE FROM users WHERE id = $1`, [testPartnerId]);
    }
    client.release();
    await pool.end();
  }
}

runSpotlightTests();
