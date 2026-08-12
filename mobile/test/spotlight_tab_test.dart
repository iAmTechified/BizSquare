import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizsquare/core/models/spotlight_model.dart';
import 'package:bizsquare/features/spotlight/widgets/spotlight_card.dart';
import 'package:bizsquare/features/spotlight/spotlight_screen.dart';
import 'package:bizsquare/features/spotlight/spotlight_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Spotlight Domain Models Serialization & Turn State Tests', () {
    test('Parses SpotlightCurrentModel in NOT MY TURN state', () {
      final json = {
        'campaignId': 'camp-100',
        'isMyTurn': false,
        'turnStatus': 'not_my_turn',
        'cycleNumber': 2,
        'cycleStartDate': '2026-08-10T00:00:00Z',
        'cycleEndDate': '2026-08-16T23:59:59Z',
        'submissionStatus': 'verified',
        'submissionRequirement': {
          'prompt': 'Share your seasonal discounts.',
          'maxCharacters': 250,
          'placeholder': 'e.g. Back to school discount...',
        },
        'user': {
          'id': 'u-500',
          'businessName': 'Kemi Fabrics',
          'fullName': 'Kemi Adebayo',
          'phoneNumber': '+2348012345678',
          'avatarId': 3,
          'primaryOffer': 'Fabrics & Textiles',
        },
        'content': {
          'title': 'Kemi Fabrics Clearance',
          'promoText': '30% off all silk and lace materials!',
          'caption': '#KemiFabrics #BizSquare',
        },
        'targetParticipants': 48,
        'participantCount': 19,
        'hasParticipated': false,
      };

      final model = SpotlightCurrentModel.fromJson(json);

      expect(model.isMyTurn, isFalse);
      expect(model.turnStatus, equals(SpotlightTurnStatus.notMyTurn));
      expect(model.cycleNumber, equals(2));
      expect(model.user?.businessName, equals('Kemi Fabrics'));
      expect(model.content?.title, equals('Kemi Fabrics Clearance'));
      expect(model.participantCount, equals(19));
      expect(model.targetParticipants, equals(48));
      expect(model.requirement.maxCharacters, equals(250));
      expect(model.hasParticipated, isFalse);
    });

    test('Parses SpotlightCurrentModel in MY TURN state with pending verification', () {
      final json = {
        'campaignId': 'camp-200',
        'isMyTurn': true,
        'turnStatus': 'my_turn',
        'cycleNumber': 3,
        'cycleStartDate': '2026-08-12T00:00:00Z',
        'cycleEndDate': '2026-08-18T23:59:59Z',
        'submissionStatus': 'pending',
        'user': {
          'id': 'u-my-id',
          'businessName': 'Ada Tech Solutions',
          'fullName': 'Ada Lovelace',
          'avatarId': 1,
          'primaryOffer': 'Software & Cloud',
        },
        'content': {
          'title': 'Ada Tech Cloud Hosting Launch',
          'promoText': 'Free 3-month setup for verified businesses on BizSquare.',
          'caption': '#AdaTech #BizSquare',
        },
        'targetParticipants': 50,
        'participantCount': 0,
        'hasParticipated': false,
      };

      final model = SpotlightCurrentModel.fromJson(json);

      expect(model.isMyTurn, isTrue);
      expect(model.turnStatus, equals(SpotlightTurnStatus.myTurn));
      expect(model.submissionStatus, equals(SpotlightSubmissionStatus.pending));
      expect(model.user?.businessName, equals('Ada Tech Solutions'));
    });

    test('Serializes and deserializes SpotlightSubmissionDraft', () {
      final draft = SpotlightSubmissionDraft(
        title: 'Draft Campaign Title',
        promoText: 'Draft promo description saved locally.',
        caption: '#DraftTag',
        lastSaved: DateTime(2026, 8, 12, 14, 0),
      );

      final map = draft.toJson();
      final restored = SpotlightSubmissionDraft.fromJson(map);

      expect(restored.title, equals('Draft Campaign Title'));
      expect(restored.promoText, equals('Draft promo description saved locally.'));
      expect(restored.caption, equals('#DraftTag'));
    });

    test('Parses SpotlightHistoryItem for Mine and Others tabs', () {
      final mineJson = {
        'campaignId': 'camp-300',
        'title': 'My Past Spotlight',
        'promoText': 'Past promo details',
        'caption': '#Past',
        'startDate': '2026-08-01T00:00:00Z',
        'submissionStatus': 'verified',
        'participantCount': 42,
        'targetParticipants': 48,
      };

      final mineItem = SpotlightHistoryItem.fromJsonMine(mineJson);
      expect(mineItem.title, equals('My Past Spotlight'));
      expect(mineItem.participantCount, equals(42));
      expect(mineItem.submissionStatus, equals('verified'));

      final othersJson = {
        'participationId': 'part-500',
        'campaignId': 'camp-400',
        'title': 'Partner Spotlight',
        'promoText': 'Partner promo details',
        'caption': '#Partner',
        'creatorBusinessName': 'Lagos Gadgets',
        'creatorName': 'Emeka Obi',
        'creatorAvatar': 4,
        'creatorPrimaryOffer': 'Smartphones & Laptops',
        'participatedAt': '2026-08-05T12:00:00Z',
        'participantCount': 35,
      };

      final othersItem = SpotlightHistoryItem.fromJsonOthers(othersJson);
      expect(othersItem.creatorBusinessName, equals('Lagos Gadgets'));
      expect(othersItem.creatorPrimaryOffer, equals('Smartphones & Laptops'));
      expect(othersItem.participantCount, equals(35));
    });
  });

  group('2. Spotlight UI Widget Tests', () {
    testWidgets('SpotlightCard renders creator info, progress bar, and share CTA', (tester) async {
      const sampleSpotlight = SpotlightCurrentModel(
        campaignId: 'camp-sample',
        isMyTurn: false,
        cycleStartDate: '2026-08-10',
        cycleEndDate: '2026-08-16',
        user: SpotlightUserModel(
          id: 'u-1',
          businessName: 'Zainab Shoes',
          fullName: 'Zainab Bello',
          avatarId: 2,
          primaryOffer: 'Footwear & Bags',
        ),
        content: SpotlightContentModel(
          title: 'Zainab Handcrafted Leather',
          promoText: 'Pure Nigerian leather shoes at wholesale prices.',
          caption: '#ZainabShoes #BizSquare',
        ),
        targetParticipants: 48,
        participantCount: 24,
        hasParticipated: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCard(
                spotlight: sampleSpotlight,
                variant: SpotlightCardVariant.feed,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Zainab Shoes'), findsOneWidget);
      expect(find.text('Footwear & Bags'), findsOneWidget);
      expect(find.text('Zainab Handcrafted Leather'), findsOneWidget);
      expect(find.text('24 / 48 verified shares'), findsOneWidget);
      expect(find.text('Share on WhatsApp Status (+2 Points)'), findsOneWidget);
      expect(find.text('View participants'), findsOneWidget);
    });

    testWidgets('SpotlightScreen renders header and how visibility works section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpotlightScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spotlight'), findsOneWidget);
      expect(find.text('Your weekly visibility'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('How Spotlight Visibility Works'), findsOneWidget);
    });

    testWidgets('SpotlightHistoryScreen renders Mine and Others tabs with empty states', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpotlightHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spotlight History'), findsOneWidget);
      expect(find.text('Mine'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);
      expect(find.text('No Spotlight history yet.'), findsOneWidget);
      expect(find.text('Your Spotlight activity will appear here.'), findsOneWidget);
    });
  });
}
