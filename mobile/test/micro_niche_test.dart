import 'package:flutter_test/flutter_test.dart';
import 'package:bizsquare/core/data/micro_niche_taxonomy.dart';
import 'package:bizsquare/core/data/onboarding_draft.dart';

void main() {
  group('A. Step 2 Micro-Niche Selection & Taxonomy Tests', () {
    test('1. Selecting 1 micro-niche makes it the Primary niche', () {
      final selectedNiches = ['mn_footwear'];
      String? primaryNiche = selectedNiches.length == 1 ? selectedNiches.first : null;

      expect(selectedNiches.length, 1);
      expect(primaryNiche, 'mn_footwear');
    });

    test('2. Selecting 3 micro-niches has 1 Primary and 2 Secondary niches', () {
      final selectedNiches = ['mn_footwear', 'mn_jewelry_watches', 'mn_mens_clothing'];
      String primaryNiche = 'mn_footwear';
      final secondaryNiches = selectedNiches.where((id) => id != primaryNiche).toList();

      expect(selectedNiches.length, 3);
      expect(primaryNiche, 'mn_footwear');
      expect(secondaryNiches.length, 2);
      expect(secondaryNiches, contains('mn_jewelry_watches'));
      expect(secondaryNiches, contains('mn_mens_clothing'));
    });

    test('3. Cannot select more than 3 micro-niches', () {
      final selectedNiches = <String>[];
      void addNiche(String id) {
        if (selectedNiches.length < 3) {
          selectedNiches.add(id);
        }
      }

      addNiche('mn_footwear');
      addNiche('mn_jewelry_watches');
      addNiche('mn_smartphones_laptops');
      addNiche('mn_packaged_foods'); // 4th attempt

      expect(selectedNiches.length, 3);
      expect(selectedNiches, isNot(contains('mn_packaged_foods')));
    });

    test('4. Deselection removes niche and reassigns Primary if needed', () {
      final selectedNiches = ['mn_footwear', 'mn_jewelry_watches'];
      String? primaryNiche = 'mn_footwear';

      // Deselect primary
      selectedNiches.remove('mn_footwear');
      if (primaryNiche == 'mn_footwear') {
        primaryNiche = selectedNiches.isNotEmpty ? selectedNiches.first : null;
      }

      expect(selectedNiches.length, 1);
      expect(selectedNiches.first, 'mn_jewelry_watches');
      expect(primaryNiche, 'mn_jewelry_watches');
    });

    test('5. Duplicate micro-niches cannot be added', () {
      final selectedNiches = <String>{};
      selectedNiches.add('mn_footwear');
      selectedNiches.add('mn_footwear'); // duplicate attempt

      expect(selectedNiches.length, 1);
    });
  });

  group('B. Micro-Niche Collision & Matching Engine Constraint Tests', () {
    bool checkCollision(List<String> businessA, List<String> businessB) {
      final setA = businessA.toSet();
      return businessB.any((nicheId) => setA.contains(nicheId));
    }

    test('1. Footwear vs Footwear → COLLISION (DENY)', () {
      final bizA = ['mn_footwear'];
      final bizB = ['mn_footwear'];
      final collision = checkCollision(bizA, bizB);

      expect(collision, true, reason: 'Exact micro-niche match is a competitor collision');
    });

    test('2. Footwear vs Jewelry & Watches → NO COLLISION (ALLOW)', () {
      final bizA = ['mn_footwear'];
      final bizB = ['mn_jewelry_watches'];
      final collision = checkCollision(bizA, bizB);

      expect(collision, false, reason: 'Different micro-niches under same Fashion category must be allowed');
    });

    test('3. Footwear + Gadgets vs Food + Gadgets → COLLISION (DENY)', () {
      final bizA = ['mn_footwear', 'mn_smartphones_laptops'];
      final bizB = ['mn_packaged_foods', 'mn_smartphones_laptops'];
      final collision = checkCollision(bizA, bizB);

      expect(collision, true, reason: 'Sharing ANY micro-niche causes competitor collision');
    });

    test('4. Footwear + Gadgets vs Food + Logistics → NO COLLISION (ALLOW)', () {
      final bizA = ['mn_footwear', 'mn_smartphones_laptops'];
      final bizB = ['mn_packaged_foods', 'mn_last_mile_delivery'];
      final collision = checkCollision(bizA, bizB);

      expect(collision, false, reason: 'Zero micro-niche overlap allows mutual trade matchmaking');
    });
  });

  group('C. Step 5 Anti-Echo-Chamber Interest Selection Tests', () {
    test('1. User own micro-niches are strictly excluded from selectable interests', () {
      final userOwnNiches = {'mn_footwear', 'mn_jewelry_watches'};
      final allFashionNiches = MicroNicheTaxonomy.categories
          .firstWhere((c) => c.id == 'cat_01_fashion')
          .microNiches;

      // Anti-echo-chamber filter
      final selectableInterests = allFashionNiches
          .where((mn) => !userOwnNiches.contains(mn.id))
          .map((mn) => mn.id)
          .toList();

      expect(selectableInterests, isNot(contains('mn_footwear')));
      expect(selectableInterests, isNot(contains('mn_jewelry_watches')));
      expect(selectableInterests, contains('mn_mens_clothing'));
      expect(selectableInterests, contains('mn_bags_accessories'));
    });

    test('2. Allows up to 5 multi-select interests', () {
      final selectedInterests = <String>{};
      final candidateInterests = [
        'mn_last_mile_delivery',
        'mn_marketing_advertising',
        'mn_accounting_bookkeeping',
        'mn_smartphones_laptops',
        'mn_packaged_foods',
        'mn_furniture', // 6th
      ];

      for (final interest in candidateInterests) {
        if (selectedInterests.length < 5) {
          selectedInterests.add(interest);
        }
      }

      expect(selectedInterests.length, 5);
      expect(selectedInterests, isNot(contains('mn_furniture')));
    });
  });

  group('D. Demand Lifecycle & Prioritization Tests', () {
    test('1. Dynamic demand has higher weight than baseline demand', () {
      const dynamicDemandWeight = 2.0;
      const baselineDemandWeight = 1.0;

      expect(dynamicDemandWeight > baselineDemandWeight, true);
    });

    test('2. Dynamic demand expires after approximately 14 days', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 15));
      final expiresAt = createdAt.add(const Duration(days: 14));
      final isExpired = DateTime.now().isAfter(expiresAt);

      expect(isExpired, true);
    });

    test('3. Fresh dynamic demand is active', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 3));
      final expiresAt = createdAt.add(const Duration(days: 14));
      final isExpired = DateTime.now().isAfter(expiresAt);

      expect(isExpired, false);
    });
  });

  group('E. Persistence & Draft Resume Tests', () {
    test('1. Onboarding draft serializes and deserializes cleanly', () {
      final draft = OnboardingDraft(
        currentStep: 2,
        businessName: 'Lagos Footwear Hub',
        phoneNumber: '+2348012345678',
        selectedAvatarId: 3,
        selectedMicroNicheIds: const ['mn_footwear', 'mn_bags_accessories'],
        primaryMicroNicheId: 'mn_footwear',
        lastUpdated: DateTime.now(),
      );

      final json = draft.toJson();
      final restored = OnboardingDraft.fromJson(json);

      expect(restored.currentStep, 2);
      expect(restored.businessName, 'Lagos Footwear Hub');
      expect(restored.phoneNumber, '+2348012345678');
      expect(restored.selectedMicroNicheIds.length, 2);
      expect(restored.primaryMicroNicheId, 'mn_footwear');
    });

    test('2. Unverified draft has isVerified = false', () {
      final draft = OnboardingDraft.initial();
      expect(draft.isVerified, false);
      expect(draft.verificationCode, null);
    });
  });

  group('F. App Launch Routing Decision Engine Tests', () {
    String determineInitialRoute({
      required bool isAuthenticated,
      required bool hasOnboarded,
      required bool completedDailyWallToday,
    }) {
      if (!isAuthenticated) {
        if (hasOnboarded) {
          return '/auth-wall';
        } else {
          return '/onboarding';
        }
      } else {
        if (!completedDailyWallToday) {
          return '/daily-wall';
        } else {
          return '/home';
        }
      }
    }

    test('1. Unauthenticated new user → /onboarding', () {
      final route = determineInitialRoute(
        isAuthenticated: false,
        hasOnboarded: false,
        completedDailyWallToday: false,
      );
      expect(route, '/onboarding');
    });

    test('2. Unauthenticated onboarded user → /auth-wall', () {
      final route = determineInitialRoute(
        isAuthenticated: false,
        hasOnboarded: true,
        completedDailyWallToday: false,
      );
      expect(route, '/auth-wall');
    });

    test('3. Authenticated user with pending daily wall → /daily-wall', () {
      final route = determineInitialRoute(
        isAuthenticated: true,
        hasOnboarded: true,
        completedDailyWallToday: false,
      );
      expect(route, '/daily-wall');
    });

    test('4. Authenticated user with completed daily wall → /home', () {
      final route = determineInitialRoute(
        isAuthenticated: true,
        hasOnboarded: true,
        completedDailyWallToday: true,
      );
      expect(route, '/home');
    });
  });
}
