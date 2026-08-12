import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/onboarding_draft.dart';

final onboardingDraftProvider = StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>((ref) {
  return OnboardingDraftNotifier();
});

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  static const _storageKey = 'bizsquare_onboarding_draft_v2';
  static const _storage = FlutterSecureStorage();

  OnboardingDraftNotifier() : super(OnboardingDraft.initial()) {
    _loadPersistedDraft();
  }

  Future<void> _loadPersistedDraft() async {
    try {
      final jsonString = await _storage.read(key: _storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final restored = OnboardingDraft.fromJson(jsonString);
        state = restored;
      }
    } catch (e) {
      debugPrint('Error restoring onboarding draft: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _storageKey, value: state.toJson());
    } catch (e) {
      debugPrint('Error persisting onboarding draft: $e');
    }
  }

  // STEP 1: Business Identity
  Future<void> updateStep1({
    required String businessName,
    required String phoneNumber,
    required int avatarId,
  }) async {
    state = state.copyWith(
      businessName: businessName.trim(),
      phoneNumber: phoneNumber.trim(),
      selectedAvatarId: avatarId,
      currentStep: 2,
      lastUpdated: DateTime.now(),
    );
    await _persist();
  }

  // STEP 2: Micro-Niche Selection
  Future<void> updateStep2({
    required List<String> microNicheIds,
    required String primaryMicroNicheId,
  }) async {
    state = state.copyWith(
      selectedMicroNicheIds: microNicheIds,
      primaryMicroNicheId: primaryMicroNicheId,
      currentStep: 3,
      lastUpdated: DateTime.now(),
    );
    await _persist();
  }

  // STEP 3: Verification Success
  Future<void> updateStep3Verified({
    required String verificationCode,
  }) async {
    state = state.copyWith(
      verificationCode: verificationCode.trim(),
      isVerified: true,
      currentStep: 4,
      lastUpdated: DateTime.now(),
    );
    await _persist();
  }

  // STEP 4: Security PIN Setup
  Future<void> updateStep4Pin({
    required String pin,
  }) async {
    state = state.copyWith(
      pin: pin.trim(),
      currentStep: 5,
      lastUpdated: DateTime.now(),
    );
    await _persist();
  }

  // STEP 5: Username & Interests
  Future<void> updateStep5({
    required String username,
    required List<String> interestIds,
  }) async {
    state = state.copyWith(
      username: username.trim(),
      selectedInterestIds: interestIds,
      lastUpdated: DateTime.now(),
    );
    await _persist();
  }

  // Jump to specific step
  Future<void> setStep(int step) async {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step);
      await _persist();
    }
  }

  // Clear draft upon successful onboarding completion
  Future<void> clearDraft() async {
    state = OnboardingDraft.initial();
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('Error clearing onboarding draft: $e');
    }
  }
}
