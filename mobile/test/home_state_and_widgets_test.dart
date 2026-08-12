import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizsquare/core/models/contact_gain_summary_model.dart';
import 'package:bizsquare/core/models/spotlight_model.dart';
import 'package:bizsquare/core/models/notification_model.dart';
import 'package:bizsquare/core/models/home_state_model.dart';
import 'package:bizsquare/features/home/widgets/home_header.dart';
import 'package:bizsquare/features/home/widgets/offline_banner.dart';
import 'package:bizsquare/features/home/widgets/setup_progress_banner.dart';
import 'package:bizsquare/features/home/widgets/contact_gain_hero_card.dart';
import 'package:bizsquare/features/home/widgets/recent_contacts_carousel.dart';
import 'package:bizsquare/features/home/widgets/spotlight_home_card.dart';

void main() {
  group('1. Contact Gain Summary Model Tests', () {
    test('Correctly parses JSON and serializes back', () {
      final json = {
        'weeklyTarget': 10,
        'gainedThisWeek': 6,
        'remainingCount': 4,
        'status': 'IN_PROGRESS',
        'syncStatus': 'SYNCED',
        'underfillReason': null,
        'batchDate': '2026-08-11',
        'recentContacts': [
          {
            'contactId': 'c-1',
            'userId': 'u-1',
            'businessName': 'Ada Shoes',
            'fullName': 'Ada Lovelace',
            'phoneNumber': '+2348000000001',
            'avatarId': 1,
            'primaryOffer': 'Footwear',
            'gainedDate': '2026-08-11T12:00:00.000Z',
            'matchReason': 'DEMAND_MATCH',
            'tier': 'TIER_1',
            'isMutual': true,
            'score': 150.0,
          }
        ],
      };

      final model = ContactGainSummaryModel.fromJson(json);
      expect(model.weeklyTarget, 10);
      expect(model.gainedThisWeek, 6);
      expect(model.remainingCount, 4);
      expect(model.status, 'IN_PROGRESS');
      expect(model.syncStatus, 'SYNCED');
      expect(model.recentContacts.length, 1);
      expect(model.recentContacts.first.businessName, 'Ada Shoes');
      expect(model.recentContacts.first.isMutual, true);
    });
  });

  group('2. Spotlight Model Tests', () {
    test('Correctly parses Community Spotlight and copyWith works', () {
      final json = {
        'campaignId': 'camp-123',
        'isMyTurn': false,
        'user': {
          'id': 'u-2',
          'businessName': 'Lagos Gadgets',
          'fullName': 'Chidi',
          'phoneNumber': '+2348000000002',
          'avatarId': 3,
          'primaryOffer': 'Smartphones',
        },
        'content': {
          'title': 'Lagos Gadgets Spotlight',
          'promoText': 'Wholesale phones in Computer Village',
          'caption': '#GrowTogether #BizSquare',
        },
        'targetParticipants': 48,
        'participantCount': 12,
        'hasParticipated': false,
        'startDate': '2026-08-11',
        'endDate': '2026-08-18',
      };

      final model = SpotlightCurrentModel.fromJson(json);
      expect(model.isMyTurn, false);
      expect(model.user?.businessName, 'Lagos Gadgets');
      expect(model.participantCount, 12);
      expect(model.hasParticipated, false);

      final updated = model.copyWith(hasParticipated: true, participantCount: 13);
      expect(updated.hasParticipated, true);
      expect(updated.participantCount, 13);
    });
  });

  group('3. Notification Model Tests', () {
    test('Correctly parses InAppNotificationItem', () {
      final json = {
        'id': 'n-1',
        'title': 'Weekly Match Allocation Ready',
        'body': 'You have 8 new contacts in your network.',
        'type': 'contact_gain',
        'isRead': false,
        'createdAt': '2026-08-11T10:00:00.000Z',
      };

      final notif = InAppNotificationItem.fromJson(json);
      expect(notif.id, 'n-1');
      expect(notif.title, 'Weekly Match Allocation Ready');
      expect(notif.isRead, false);
    });
  });

  group('4. HomeState Setup Progress Tests', () {
    test('Calculates 1/5 to 5/5 setup step progression correctly', () {
      const state0 = HomeState(
        profileCompleted: false,
        primaryOfferSet: false,
        interestsSet: false,
        contactsPermissionGranted: false,
        notificationsPermissionGranted: false,
        completedSetupSteps: 0,
      );
      expect(state0.isFullySetup, false);

      final state3 = state0.copyWith(
        profileCompleted: true,
        primaryOfferSet: true,
        interestsSet: true,
        completedSetupSteps: 3,
      );
      expect(state3.completedSetupSteps, 3);
      expect(state3.isFullySetup, false);

      final state5 = state3.copyWith(
        contactsPermissionGranted: true,
        notificationsPermissionGranted: true,
        completedSetupSteps: 5,
      );
      expect(state5.completedSetupSteps, 5);
      expect(state5.isFullySetup, true);
    });
  });

  group('5. Home UI Widget Tests', () {
    testWidgets('HomeHeader renders user greeting and badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              businessName: 'Ade Stores',
              unreadCount: 3,
              isNewUser: false,
            ),
          ),
        ),
      );

      expect(find.text('Ade Stores'), findsOneWidget);
    });

    testWidgets('OfflineBanner displays message when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(isOffline: true),
          ),
        ),
      );

      expect(find.text("You're offline. Showing your latest information."), findsOneWidget);
    });

    testWidgets('SetupProgressBanner renders step 1 for incomplete profile', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SetupProgressBanner(
                completedSteps: 1,
                totalSteps: 5,
                profileCompleted: false,
                primaryOfferSet: false,
                interestsSet: false,
                contactsPermissionGranted: false,
                notificationsPermissionGranted: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1 / 5 COMPLETED'), findsOneWidget);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Complete profile'), findsOneWidget);
    });

    testWidgets('ContactGainHeroCard renders real statistics and progress', (tester) async {
      final summary = ContactGainSummaryModel(
        weeklyTarget: 10,
        gainedThisWeek: 7,
        remainingCount: 3,
        status: 'IN_PROGRESS',
        syncStatus: 'SYNCED',
        batchDate: '2026-08-11',
        recentContacts: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactGainHeroCard(
              summary: summary,
              hasContactPermission: true,
            ),
          ),
        ),
      );

      expect(find.text('7'), findsOneWidget);
      expect(find.text('new contacts this week'), findsOneWidget);
      expect(find.text('3 more expected'), findsOneWidget);
      expect(find.text('7 / 10 Target'), findsOneWidget);
    });

    testWidgets('RecentContactsCarousel renders horizontal cards', (tester) async {
      final contacts = [
        ContactGainRecentItem(
          contactId: 'c-1',
          userId: 'u-1',
          businessName: 'Kemi Fabrics',
          avatarId: 2,
          primaryOffer: 'Textiles',
          gainedDate: DateTime.now(),
          matchReason: 'DEMAND_MATCH',
          tier: 'TIER_1',
          isMutual: true,
          score: 120.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentContactsCarousel(contacts: contacts),
          ),
        ),
      );

      expect(find.text('New this week'), findsOneWidget);
      expect(find.text('Kemi Fabrics'), findsOneWidget);
      expect(find.text('Textiles'), findsOneWidget);
      expect(find.text('MUTUAL'), findsOneWidget);
    });

    testWidgets('SpotlightHomeCard renders community spotlight with WhatsApp share CTA', (tester) async {
      const spotlight = SpotlightCurrentModel(
        campaignId: 'c-1',
        isMyTurn: false,
        user: SpotlightUserModel(
          id: 'u-1',
          businessName: 'Tunde Auto Parts',
          fullName: 'Tunde',
          avatarId: 1,
          primaryOffer: 'Car Spare Parts',
        ),
        content: SpotlightContentModel(
          title: 'Tunde Auto Parts Spotlight',
          promoText: 'Top quality auto spares in Abuja.',
          caption: '#GrowTogether',
        ),
        targetParticipants: 48,
        participantCount: 5,
        hasParticipated: false,
        cycleStartDate: '2026-08-11',
        cycleEndDate: '2026-08-18',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpotlightHomeCard(spotlight: spotlight),
            ),
          ),
        ),
      );

      expect(find.text("TODAY'S SPOTLIGHT"), findsOneWidget);
      expect(find.text('Tunde Auto Parts'), findsOneWidget);
      expect(find.text('Share to WhatsApp'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });
  });
}
