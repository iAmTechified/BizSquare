import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../services/biometric_service.dart';
import '../services/profile_cache_service.dart';
import '../services/profile_service.dart';
import 'auth_state_provider.dart';
import 'contacts_state_provider.dart';
import 'permission_state_provider.dart';

class ProfileState {
  final UserProfileModel? profile;
  final UserSetupStatusModel setupStatus;
  final NotificationPreferencesModel notificationPrefs;
  final PrivacyPreferencesModel privacyPrefs;
  final bool isLoading;
  final bool isSaving;
  final bool isOffline;
  final String? errorMessage;
  final String? saveSuccessMessage;
  final bool hasContactsPermission;
  final DateTime? lastSyncedAt;

  const ProfileState({
    this.profile,
    this.setupStatus = const UserSetupStatusModel(),
    this.notificationPrefs = const NotificationPreferencesModel(),
    this.privacyPrefs = const PrivacyPreferencesModel(),
    this.isLoading = true,
    this.isSaving = false,
    this.isOffline = false,
    this.errorMessage,
    this.saveSuccessMessage,
    this.hasContactsPermission = false,
    this.lastSyncedAt,
  });

  ProfileState copyWith({
    UserProfileModel? profile,
    UserSetupStatusModel? setupStatus,
    NotificationPreferencesModel? notificationPrefs,
    PrivacyPreferencesModel? privacyPrefs,
    bool? isLoading,
    bool? isSaving,
    bool? isOffline,
    String? errorMessage,
    String? saveSuccessMessage,
    bool? hasContactsPermission,
    DateTime? lastSyncedAt,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      setupStatus: setupStatus ?? this.setupStatus,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      privacyPrefs: privacyPrefs ?? this.privacyPrefs,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      saveSuccessMessage: saveSuccessMessage,
      hasContactsPermission: hasContactsPermission ?? this.hasContactsPermission,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final cacheService = ref.watch(profileCacheServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  return ProfileStateNotifier(
    ref: ref,
    service: profileService,
    cacheService: cacheService,
    biometricService: biometricService,
  );
});

class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  final ProfileService _service;
  final ProfileCacheService _cacheService;
  final BiometricService _biometricService;

  ProfileStateNotifier({
    required Ref ref,
    required ProfileService service,
    required ProfileCacheService cacheService,
    required BiometricService biometricService,
  })  : _ref = ref,
        _service = service,
        _cacheService = cacheService,
        _biometricService = biometricService,
        super(const ProfileState()) {
    loadProfile();
  }

  /// Initial load with cache-first strategy
  Future<void> loadProfile({bool forceRefresh = false}) async {
    // 1. Hydrate from Cache
    final cached = await _cacheService.getCachedProfile();
    final cachedSetup = await _cacheService.getCachedSetupStatus();
    final cachedNotif = await _cacheService.getNotificationPrefs();
    final cachedPriv = await _cacheService.getPrivacyPrefs();

    final permissionState = _ref.read(permissionStateProvider);

    if (cached != null) {
      state = state.copyWith(
        profile: cached,
        setupStatus: cachedSetup ?? state.setupStatus,
        notificationPrefs: cachedNotif,
        privacyPrefs: cachedPriv,
        isLoading: false,
        hasContactsPermission: permissionState.contactsGranted,
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Fetch Fresh Data from Server in Background
    try {
      final freshProfile = await _service.getProfile();
      final freshSetup = await _service.getSetupStatus();

      state = state.copyWith(
        profile: freshProfile,
        setupStatus: freshSetup,
        isLoading: false,
        isOffline: false,
        errorMessage: null,
      );

      // Persist to cache
      await _cacheService.cacheProfile(freshProfile);
      await _cacheService.cacheSetupStatus(freshSetup);
    } catch (e) {
      debugPrint('Profile fetch network error: $e');
      if (cached != null) {
        state = state.copyWith(
          isOffline: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load profile. Please check your internet connection.',
        );
      }
    }
  }

  /// Updates profile identity details (Name, Business Name, Avatar ID)
  Future<bool> updateProfileIdentity({
    String? businessName,
    String? fullName,
    int? avatarId,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final updated = await _service.updateProfile(
        businessName: businessName,
        fullName: fullName,
        avatarId: avatarId,
      );

      state = state.copyWith(
        profile: updated,
        isSaving: false,
        saveSuccessMessage: 'Profile saved successfully',
      );

      await _cacheService.cacheProfile(updated);

      // Update global UserState
      _ref.read(userStateProvider.notifier).updateProfileInfo(
            businessName: updated.businessName,
            avatarId: updated.avatarId,
          );

      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save profile changes. Please try again.',
      );
      return false;
    }
  }

  /// Updates Primary Offer and Secondary Offers
  Future<bool> updateOffers({
    required String primaryMicroNicheId,
    required List<String> secondaryMicroNicheIds,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final updatedNiches = await _service.updateOffers(
        primaryMicroNicheId: primaryMicroNicheId,
        secondaryMicroNicheIds: secondaryMicroNicheIds,
      );

      if (state.profile != null) {
        final newProfile = state.profile!.copyWith(supplyNiches: updatedNiches);
        state = state.copyWith(
          profile: newProfile,
          isSaving: false,
          saveSuccessMessage: 'Business offerings updated',
        );
        await _cacheService.cacheProfile(newProfile);
      } else {
        state = state.copyWith(isSaving: false);
      }

      // Re-fetch setup status
      final setup = await _service.getSetupStatus();
      state = state.copyWith(setupStatus: setup);
      await _cacheService.cacheSetupStatus(setup);

      return true;
    } catch (e) {
      debugPrint('Update offers error: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save offerings. Please try again.',
      );
      return false;
    }
  }

  /// Updates Baseline Interests
  Future<bool> updateInterests(List<String> taxonomyIds) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await _service.updateBaselineInterests(taxonomyIds);

      // Reload fresh profile to get full taxonomy objects
      final fresh = await _service.getProfile();
      final setup = await _service.getSetupStatus();

      state = state.copyWith(
        profile: fresh,
        setupStatus: setup,
        isSaving: false,
        saveSuccessMessage: 'Interests saved successfully',
      );

      await _cacheService.cacheProfile(fresh);
      await _cacheService.cacheSetupStatus(setup);

      return true;
    } catch (e) {
      debugPrint('Update interests error: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save interests. Please try again.',
      );
      return false;
    }
  }

  /// Updates Notification Preferences
  Future<void> updateNotificationPrefs(NotificationPreferencesModel prefs) async {
    state = state.copyWith(notificationPrefs: prefs);
    await _cacheService.cacheNotificationPrefs(prefs);
  }

  /// Updates Privacy Preferences
  Future<void> updatePrivacyPrefs(PrivacyPreferencesModel prefs) async {
    state = state.copyWith(privacyPrefs: prefs);
    await _cacheService.cachePrivacyPrefs(prefs);
  }

  /// Changes 4-digit security PIN
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await _service.changePin(currentPin: currentPin, newPin: newPin);
      state = state.copyWith(
        isSaving: false,
        saveSuccessMessage: 'PIN changed successfully',
      );
      return true;
    } catch (e) {
      debugPrint('Change PIN error: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not change PIN. Please check current PIN and try again.',
      );
      return false;
    }
  }

  /// Requests real OS contact permission & triggers sync
  Future<void> syncContactsNow() async {
    state = state.copyWith(isSaving: true);
    try {
      final contactsNotifier = _ref.read(contactsStateProvider.notifier);
      await contactsNotifier.requestContactsPermission();
      await contactsNotifier.refresh();
      state = state.copyWith(
        isSaving: false,
        lastSyncedAt: DateTime.now(),
        hasContactsPermission: true,
      );
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  /// Signs out authenticated user completely
  Future<void> signOut() async {
    await _cacheService.clearCache();
    await _biometricService.clearLinkedAccount();
    _ref.read(userStateProvider.notifier).logout();
  }

  /// Deactivates user account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isSaving: true);
    try {
      await _service.deactivateAccount();
      await signOut();
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not deactivate account. Please try again later.',
      );
      return false;
    }
  }
}
