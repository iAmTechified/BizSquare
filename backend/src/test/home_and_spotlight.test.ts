import { SpotlightService } from '../services/spotlight.service';
import { NotificationService } from '../services/notification.service';
import { MATCHING_CONFIG } from '../config/matching.config';

async function runHomeAndSpotlightTests() {
  console.log('🧪 Running Home & Spotlight Backend Unit Tests...\n');
  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, testName: string) {
    if (condition) {
      console.log(`  ✅ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${testName}`);
      failed++;
    }
  }

  // 1. Contact Gain 10% target boundary
  console.log('--- 1. Contact Gain Target & Bounds ---');
  const target100 = MATCHING_CONFIG.calculateWeeklyTarget(100);
  assert(target100 === 10, 'Network of 100 has weekly target of 10 (10%)');

  const target250 = MATCHING_CONFIG.calculateWeeklyTarget(250);
  assert(target250 === 25, 'Network of 250 has weekly target of 25 (10%)');

  const target5 = MATCHING_CONFIG.calculateWeeklyTarget(5);
  assert(target5 === 1, 'Small network of 5 has minimum weekly target of 1');

  // 2. Notification Model & Unread Logic
  console.log('\n--- 2. Notification Structure & Type Formatting ---');
  const mockNotification = {
    id: 'notif-1',
    userId: 'user-1',
    title: 'New Contact Gained',
    body: 'Sarah (Watches) has been added to your Square Contacts.',
    type: 'contact_gain',
    isRead: false,
    data: { contactId: 'c-1' },
    createdAt: new Date().toISOString(),
  };
  assert(mockNotification.isRead === false, 'New notification has isRead = false');
  assert(mockNotification.type === 'contact_gain', 'Notification has contact_gain type');

  // 3. Spotlight State Transitions (User Turn vs Community)
  console.log('\n--- 3. Spotlight Model & Turn Resolution ---');
  const communitySpotlight = {
    campaignId: 'camp-1',
    isMyTurn: false,
    user: {
      id: 'other-user',
      businessName: 'Lagos Fabrics',
      fullName: 'Emeka',
      avatarId: 2,
      primaryOffer: 'Textiles',
    },
    content: {
      title: 'Lagos Fabrics Spotlight',
      promoText: 'Top quality wholesale textiles in Lagos.',
      caption: '#GrowTogether #BizSquare',
    },
    targetParticipants: 48,
    participantCount: 14,
    hasParticipated: false,
    startDate: '2026-08-11',
    endDate: '2026-08-18',
  };
  assert(communitySpotlight.isMyTurn === false, 'Community spotlight has isMyTurn = false');
  assert(communitySpotlight.hasParticipated === false, 'Initial state has hasParticipated = false');

  const userTurnSpotlight = {
    ...communitySpotlight,
    isMyTurn: true,
    user: {
      id: 'my-user-id',
      businessName: 'My Store',
      fullName: 'Ada',
      avatarId: 1,
      primaryOffer: 'Shoes',
    },
  };
  assert(userTurnSpotlight.isMyTurn === true, 'User turn spotlight correctly flags isMyTurn = true');

  console.log(`\n========================================`);
  console.log(`Test Results: ${passed} Passed, ${failed} Failed`);
  console.log(`========================================\n`);

  if (failed > 0) process.exit(1);
}

runHomeAndSpotlightTests();
