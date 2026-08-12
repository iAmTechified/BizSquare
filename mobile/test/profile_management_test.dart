import 'package:flutter_test/flutter_test.dart';
import 'package:bizsquare/core/models/user_profile_model.dart';

void main() {
  group('UserProfileModel Tests', () {
    test('Correctly parses complete user profile JSON', () {
      final json = {
        'id': 'usr-12345',
        'phone_number': '+2348012345678',
        'full_name': 'Amara Okonkwo',
        'business_name': 'Amara Luxe Wears',
        'username': 'amaraluxe',
        'avatar_id': 4,
        'akawo_points': 18,
        'is_active': true,
        'onboarding_completed': true,
        'verification_status': 'verified',
        'created_at': '2026-08-01T12:00:00.000Z',
        'supplyNiches': [
          {
            'micro_niche_id': 'mn_shoes',
            'is_primary': true,
            'name': 'Luxury Footwear',
          },
          {
            'micro_niche_id': 'mn_bags',
            'is_primary': false,
            'name': 'Handbags & Purses',
          },
        ],
        'baselineInterests': [
          {
            'taxonomy_id': 'tax_1',
            'name': 'Fashion & Apparel',
            'slug': 'fashion-apparel',
          },
        ],
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.id, 'usr-12345');
      expect(profile.displayName, 'Amara Luxe Wears');
      expect(profile.phoneNumber, '+2348012345678');
      expect(profile.username, 'amaraluxe');
      expect(profile.avatarId, 4);
      expect(profile.akawoPoints, 18);
      expect(profile.verificationStatus, 'verified');

      // Primary offer verification
      expect(profile.primaryOffer, isNotNull);
      expect(profile.primaryOffer!.microNicheId, 'mn_shoes');
      expect(profile.primaryOffer!.name, 'Luxury Footwear');
      expect(profile.primaryOffer!.isPrimary, isTrue);

      // Secondary offers verification
      expect(profile.secondaryOffers.length, 1);
      expect(profile.secondaryOffers.first.microNicheId, 'mn_bags');
      expect(profile.secondaryOffers.first.name, 'Handbags & Purses');
      expect(profile.secondaryOffers.first.isPrimary, isFalse);

      // Baseline interests verification
      expect(profile.baselineInterests.length, 1);
      expect(profile.baselineInterests.first.name, 'Fashion & Apparel');
    });

    test('Falls back to full_name or phone_number if business_name is missing', () {
      final p1 = UserProfileModel(
        id: '1',
        phoneNumber: '+2349000000000',
        fullName: 'Jane Doe',
        businessName: null,
        createdAt: DateTime.now(),
      );
      expect(p1.displayName, 'Jane Doe');

      final p2 = UserProfileModel(
        id: '2',
        phoneNumber: '+2349000000000',
        fullName: null,
        businessName: '',
        createdAt: DateTime.now(),
      );
      expect(p2.displayName, '+2349000000000');
    });
  });

  group('UserSetupStatusModel Tests', () {
    test('Calculates remaining count correctly when incomplete', () {
      const status = UserSetupStatusModel(
        profileCompleted: true,
        primaryOfferSet: false,
        interestsSet: false,
        onboardingCompleted: true,
      );

      expect(status.remainingCount, 2);
      expect(status.isAllCompleted, isFalse);
    });

    test('Returns isAllCompleted = true when 3 required flags are set', () {
      const status = UserSetupStatusModel(
        profileCompleted: true,
        primaryOfferSet: true,
        interestsSet: true,
        onboardingCompleted: true,
      );

      expect(status.remainingCount, 0);
      expect(status.isAllCompleted, isTrue);
    });
  });

  group('Preferences Models Tests', () {
    test('NotificationPreferencesModel copyWith works', () {
      const initial = NotificationPreferencesModel(
        spotlightUpdates: true,
        contactGainUpdates: true,
        accountAlerts: true,
      );

      final updated = initial.copyWith(spotlightUpdates: false);
      expect(updated.spotlightUpdates, isFalse);
      expect(updated.contactGainUpdates, isTrue);
      expect(updated.accountAlerts, isTrue);
    });

    test('PrivacyPreferencesModel copyWith works', () {
      const initial = PrivacyPreferencesModel(
        discoverableInContactGain: true,
        showBusinessOnSpotlight: true,
      );

      final updated = initial.copyWith(showBusinessOnSpotlight: false);
      expect(updated.discoverableInContactGain, isTrue);
      expect(updated.showBusinessOnSpotlight, isFalse);
    });
  });
}
