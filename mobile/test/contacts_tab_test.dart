import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizsquare/core/models/unified_contact_model.dart';
import 'package:bizsquare/core/utils/phone_normalizer.dart';
import 'package:bizsquare/core/services/contact_repository.dart';
import 'package:bizsquare/features/contacts/widgets/contact_card.dart';
import 'package:bizsquare/features/contacts/widgets/square_contacts_tab.dart';
import 'package:bizsquare/features/contacts/widgets/all_contacts_tab.dart';
import 'package:bizsquare/features/contacts/widgets/contacts_search_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. PhoneNormalizer & Canonical Identity Tests', () {
    test('Normalizes Nigerian local 0-prefixed numbers to E.164', () {
      expect(PhoneNormalizer.normalize('08012345678'), equals('+2348012345678'));
      expect(PhoneNormalizer.normalize('0703 456 7890'), equals('+2347034567890'));
      expect(PhoneNormalizer.normalize('090-123-45678'), equals('+2349012345678'));
    });

    test('Normalizes numbers with existing country code and punctuation', () {
      expect(PhoneNormalizer.normalize('+234 (801) 234-5678'), equals('+2348012345678'));
      expect(PhoneNormalizer.normalize('2348012345678'), equals('+2348012345678'));
    });

    test('Formats display phone numbers with spacing', () {
      expect(PhoneNormalizer.formatDisplay('+2348012345678'), equals('+234 801 234 5678'));
    });

    test('Identifies valid WhatsApp candidates', () {
      expect(PhoneNormalizer.isValidWhatsAppCandidate('08012345678'), isTrue);
      expect(PhoneNormalizer.isValidWhatsAppCandidate('+2348012345678'), isTrue);
      expect(PhoneNormalizer.isValidWhatsAppCandidate('123'), isFalse);
    });

    test('Constructs direct WhatsApp link', () {
      final url = PhoneNormalizer.getWhatsAppUrl('+2348012345678', defaultMessage: 'Hello');
      expect(url, contains('https://wa.me/2348012345678?text=Hello'));
    });
  });

  group('2. UnifiedContactModel Serialization Tests', () {
    test('Parses Square Contact from JSON', () {
      final json = {
        'id': 'c-100',
        'userId': 'u-200',
        'fullName': 'Ada Lovelace',
        'businessName': 'Ada Tech Ltd',
        'phoneNumber': '+2348012345678',
        'avatarId': 3,
        'primaryOffer': 'Cloud Infrastructure',
        'isSquareContact': true,
        'isStarred': true,
        'isArchived': false,
        'labels': ['VIP', 'Tech'],
        'gainedDate': '2026-08-11T12:00:00Z',
        'syncStatus': 'SYNCED',
      };

      final model = UnifiedContactModel.fromJson(json);
      expect(model.id, equals('c-100'));
      expect(model.fullName, equals('Ada Lovelace'));
      expect(model.primaryOffer, equals('Cloud Infrastructure'));
      expect(model.isSquareContact, isTrue);
      expect(model.isStarred, isTrue);
      expect(model.labels, contains('VIP'));
      expect(model.syncState, equals(ContactSyncState.synced));
    });
  });

  group('3. Contact Duplicate Detection Tests', () {
    test('Detects contacts sharing the same canonical phone number', () {
      final contacts = [
        const UnifiedContactModel(
          id: 'c-1',
          fullName: 'Sarah Johnson',
          phoneNumber: '0801 234 5678',
          canonicalPhone: '+2348012345678',
          isSquareContact: true,
        ),
        const UnifiedContactModel(
          id: 'c-2',
          fullName: 'Sarah J.',
          phoneNumber: '+2348012345678',
          canonicalPhone: '+2348012345678',
          isSquareContact: false,
        ),
        const UnifiedContactModel(
          id: 'c-3',
          fullName: 'Unique Contact',
          phoneNumber: '+2348099999999',
          canonicalPhone: '+2348099999999',
        ),
      ];

      final repo = ContactRepository();
      final duplicates = repo.detectDuplicates(contacts);

      expect(duplicates.length, equals(1));
      expect(duplicates[0].primary.id, equals('c-1'));
      expect(duplicates[0].duplicate.id, equals('c-2'));
      expect(duplicates[0].reason, contains('Identical phone number'));
    });
  });

  group('4. Contact UI Widget Tests', () {
    testWidgets('ContactCard renders collapsed state and expands on tap', (tester) async {
      bool starToggled = false;
      bool expanded = false;

      final contact = UnifiedContactModel(
        id: 'c-test',
        fullName: 'Chukwudi Eze',
        businessName: 'Eze Logistics',
        phoneNumber: '+2348012345678',
        canonicalPhone: '+2348012345678',
        avatarId: 1,
        primaryOffer: 'Interstate Freight',
        isSquareContact: true,
        isStarred: false,
        labels: const ['Logistics'],
        gainedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ContactCard(
                  contact: contact,
                  isExpanded: expanded,
                  onTap: () => setState(() => expanded = !expanded),
                  onLongPress: () {},
                  onStarToggle: () => setState(() => starToggled = !starToggled),
                  onArchive: () {},
                  onSelectToggle: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Chukwudi Eze'), findsOneWidget);
      expect(find.text('Eze Logistics'), findsOneWidget);
      expect(find.text('SQUARE'), findsOneWidget);

      // Tap to expand
      await tester.tap(find.text('Chukwudi Eze'));
      await tester.pump(const Duration(milliseconds: 300));

      // Expanded items should now be visible
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Logistics'), findsOneWidget);
    });

    testWidgets('SquareContactsTab renders Top Weekly Info Card and timeline', (tester) async {
      final now = DateTime.now();
      final contacts = [
        UnifiedContactModel(
          id: 'c-1',
          fullName: 'Tunde Bakare',
          phoneNumber: '+2348011111111',
          canonicalPhone: '+2348011111111',
          primaryOffer: 'Solar Power',
          isSquareContact: true,
          gainedDate: now,
        ),
        UnifiedContactModel(
          id: 'c-2',
          fullName: 'Grace Hopper',
          phoneNumber: '+2348022222222',
          canonicalPhone: '+2348022222222',
          primaryOffer: 'Compiler Design',
          isSquareContact: true,
          gainedDate: now.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SquareContactsTab(
              contacts: contacts,
              onRefresh: () async {},
              onCardToggle: (_) {},
              onStarToggle: (_) {},
              onArchive: (_) {},
              onSelectToggle: (_, __) {},
              onLongPress: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('2 new contacts'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Tunde Bakare'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);
    });

    testWidgets('AllContactsTab renders permission request when access is not granted', (tester) async {
      bool permissionRequested = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllContactsTab(
              contacts: const [],
              hasPermission: false,
              isPermanentlyDenied: false,
              onRefresh: () async {},
              onRequestPermission: () => permissionRequested = true,
              onCardToggle: (_) {},
              onStarToggle: (_) {},
              onArchive: (_) {},
              onSelectToggle: (_, __) {},
              onLongPress: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Your contacts are waiting'), findsOneWidget);
      expect(find.text('Allow access'), findsOneWidget);

      await tester.tap(find.text('Allow access'));
      expect(permissionRequested, isTrue);
    });

    testWidgets('ContactsSearchBar triggers onChanged and clear callback', (tester) async {
      String query = '';
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ContactsSearchBar(
                  value: query,
                  onChanged: (val) => setState(() => query = val),
                  onClear: () => setState(() => cleared = true),
                );
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Solar');
      await tester.pump();
      expect(query, equals('Solar'));

      // Tap clear button
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(query, equals(''));
      expect(cleared, isTrue);
    });
  });
}
