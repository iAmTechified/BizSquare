import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';

// Theme Mode Provider (Default is system default)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Global User State
class UserState {
  final bool isAuthenticated;
  final bool hasOnboarded;
  final bool completedDailyWallToday;
  final int registrationStep; // 1 to 5
  final String? jwtToken;
  final String? businessName;
  final String? phoneNumber;
  final int avatarId;
  final String? username;
  final List<String> supplyMicroNicheIds;
  final String? primaryMicroNicheId;
  final List<String> baselineDemandIds;
  final String verificationStatus; // 'unverified', 'verified'
  final bool onboardingCompleted;

  const UserState({
    this.isAuthenticated = false,
    this.hasOnboarded = false,
    this.completedDailyWallToday = false,
    this.registrationStep = 1,
    this.jwtToken,
    this.businessName,
    this.phoneNumber,
    this.avatarId = 1,
    this.username,
    this.supplyMicroNicheIds = const [],
    this.primaryMicroNicheId,
    this.baselineDemandIds = const [],
    this.verificationStatus = 'unverified',
    this.onboardingCompleted = false,
  });

  UserState copyWith({
    bool? isAuthenticated,
    bool? hasOnboarded,
    bool? completedDailyWallToday,
    int? registrationStep,
    String? jwtToken,
    String? businessName,
    String? phoneNumber,
    int? avatarId,
    String? username,
    List<String>? supplyMicroNicheIds,
    String? primaryMicroNicheId,
    List<String>? baselineDemandIds,
    String? verificationStatus,
    bool? onboardingCompleted,
  }) {
    return UserState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      completedDailyWallToday: completedDailyWallToday ?? this.completedDailyWallToday,
      registrationStep: registrationStep ?? this.registrationStep,
      jwtToken: jwtToken ?? this.jwtToken,
      businessName: businessName ?? this.businessName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarId: avatarId ?? this.avatarId,
      username: username ?? this.username,
      supplyMicroNicheIds: supplyMicroNicheIds ?? this.supplyMicroNicheIds,
      primaryMicroNicheId: primaryMicroNicheId ?? this.primaryMicroNicheId,
      baselineDemandIds: baselineDemandIds ?? this.baselineDemandIds,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class UserStateNotifier extends StateNotifier<UserState> {
  final BiometricService _bioService = BiometricService();

  UserStateNotifier() : super(const UserState()) {
    initFromStorage();
  }

  /// Restores persistent state from secure storage
  Future<void> initFromStorage() async {
    try {
      final hasOnboarded = await _bioService.hasCompletedOnboarding();
      final linked = await _bioService.getLinkedAccount();

      if (linked != null) {
        final token = linked['token'] as String;
        final phone = linked['phoneNumber'] as String;
        final user = (linked['user'] as Map<String, dynamic>?) ?? {};

        state = state.copyWith(
          isAuthenticated: true,
          hasOnboarded: true,
          jwtToken: token,
          phoneNumber: phone,
          businessName: user['business_name'] as String? ?? user['full_name'] as String?,
          username: user['username'] as String?,
          avatarId: user['avatar_id'] as int? ?? 1,
          verificationStatus: user['verification_status'] as String? ?? 'verified',
          onboardingCompleted: user['onboarding_completed'] as bool? ?? true,
          completedDailyWallToday: false,
        );
      } else {
        state = state.copyWith(hasOnboarded: hasOnboarded);
      }
    } catch (_) {}
  }

  Future<void> setOnboarded(bool value) async {
    state = state.copyWith(hasOnboarded: value);
    await _bioService.setOnboardedFlag(value);
  }

  /// Called after Step 3 successful verification
  Future<void> completeVerification({
    required String token,
    required String businessName,
    required String phoneNumber,
    required int avatarId,
    required List<String> supplyMicroNicheIds,
    required String primaryMicroNicheId,
  }) async {
    state = state.copyWith(
      jwtToken: token,
      businessName: businessName,
      phoneNumber: phoneNumber,
      avatarId: avatarId,
      supplyMicroNicheIds: supplyMicroNicheIds,
      primaryMicroNicheId: primaryMicroNicheId,
      verificationStatus: 'verified',
      registrationStep: 4,
      hasOnboarded: true,
    );
    await _bioService.setOnboardedFlag(true);
  }

  /// Called after Step 5 Welcome to the Square
  Future<void> completeOnboarding({
    required String username,
    required List<String> baselineDemandIds,
  }) async {
    state = state.copyWith(
      username: username,
      baselineDemandIds: baselineDemandIds,
      isAuthenticated: true,
      hasOnboarded: true,
      onboardingCompleted: true,
      registrationStep: 5,
      completedDailyWallToday: false,
    );

    await _bioService.saveLinkedAccount(
      token: state.jwtToken ?? '',
      phoneNumber: state.phoneNumber ?? '',
      user: {
        'business_name': state.businessName,
        'phone_number': state.phoneNumber,
        'username': username,
        'avatar_id': state.avatarId,
        'verification_status': 'verified',
        'onboarding_completed': true,
      },
    );
  }

  void completeDailyWall() {
    state = state.copyWith(completedDailyWallToday: true);
  }

  Future<void> login({
    required String token,
    required Map<String, dynamic> user,
    List<dynamic>? supplyNiches,
    List<dynamic>? baselineDemand,
  }) async {
    final nicheIds = supplyNiches?.map((n) => n['micro_niche_id'].toString()).toList() ?? [];
    final primaryNiche = supplyNiches?.firstWhere((n) => n['is_primary'] == true, orElse: () => null)?['micro_niche_id']?.toString();
    final demandIds = baselineDemand?.map((d) => d['micro_niche_id'].toString()).toList() ?? [];

    final phone = (user['phone_number'] as String?) ?? '';
    final businessName = (user['business_name'] as String?) ?? (user['full_name'] as String?);
    final username = user['username'] as String?;
    final avatarId = user['avatar_id'] as int? ?? 1;

    state = state.copyWith(
      isAuthenticated: true,
      hasOnboarded: true,
      jwtToken: token,
      phoneNumber: phone,
      businessName: businessName,
      username: username,
      avatarId: avatarId,
      supplyMicroNicheIds: nicheIds,
      primaryMicroNicheId: primaryNiche,
      baselineDemandIds: demandIds,
      verificationStatus: user['verification_status'] as String? ?? 'verified',
      onboardingCompleted: user['onboarding_completed'] as bool? ?? true,
      completedDailyWallToday: false,
    );

    // Save to secure storage so biometrics & session are linked
    await _bioService.saveLinkedAccount(
      token: token,
      phoneNumber: phone,
      user: user,
    );
  }

  Future<void> logout() async {
    state = const UserState(hasOnboarded: true);
    await _bioService.clearLinkedAccount();
  }
}

final userStateProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  return UserStateNotifier();
});
