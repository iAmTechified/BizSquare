import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state_model.dart';
import '../services/home_service.dart';
import '../services/spotlight_service.dart';
import '../services/home_cache_service.dart';
import 'auth_state_provider.dart';
import 'permission_state_provider.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, HomeState>((ref) {
  final homeService = ref.watch(homeServiceProvider);
  final spotlightService = ref.watch(spotlightServiceProvider);
  final userState = ref.watch(userStateProvider);
  final permState = ref.watch(permissionStateProvider);
  return HomeStateNotifier(homeService, spotlightService, userState, permState, ref);
});

class HomeStateNotifier extends StateNotifier<HomeState> {
  final HomeService _homeService;
  final SpotlightService _spotlightService;
  final UserState _userState;
  final Ref _ref;

  HomeStateNotifier(
    this._homeService,
    this._spotlightService,
    this._userState,
    PermissionState permState,
    this._ref,
  ) : super(HomeState(
          userName: _userState.username ?? _userState.businessName,
          businessName: _userState.businessName,
          avatarId: _userState.avatarId,
          contactsPermissionGranted: permState.isContactsGranted,
          notificationsPermissionGranted: permState.isNotificationGranted,
        )) {
    loadHomeData();
  }

  /// Initial load: Instant cache load + Silent background refresh
  Future<void> loadHomeData() async {
    // 1. Load cached data first for instant UI response
    final cachedContactGain = await HomeCacheService.getCachedContactGain();
    final cachedSpotlight = await HomeCacheService.getCachedSpotlight();
    final cachedSetup = await HomeCacheService.getCachedSetupStatus();

    if (cachedContactGain != null || cachedSpotlight != null) {
      state = state.copyWith(
        contactGain: cachedContactGain,
        spotlight: cachedSpotlight,
        profileCompleted: cachedSetup?['profileCompleted'] ?? (_userState.businessName != null),
        primaryOfferSet: cachedSetup?['primaryOfferSet'] ?? (_userState.primaryMicroNicheId != null),
        interestsSet: cachedSetup?['interestsSet'] ?? (_userState.baselineDemandIds.isNotEmpty),
      );
      _recalculateSetupSteps();
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Fetch fresh data from backend
    await _fetchFreshData();
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    await _fetchFreshData();
  }

  Future<void> _fetchFreshData() async {
    try {
      // Re-verify OS permissions
      await _ref.read(permissionStateProvider.notifier).checkAllPermissions();
      final currentPerms = _ref.read(permissionStateProvider);

      final results = await Future.wait([
        _homeService.getContactGainSummary().then<dynamic>((v) => v).catchError((_) => null),
        _spotlightService.getCurrentSpotlight().then<dynamic>((v) => v).catchError((_) => null),
        _homeService.getUserSetupStatus().then<dynamic>((v) => v).catchError((_) => null),
      ]);

      final freshContactGain = results[0];
      final freshSpotlight = results[1];
      final freshSetup = results[2];

      final profileDone = freshSetup != null
          ? (freshSetup['profileCompleted'] == true)
          : (_userState.businessName != null && _userState.businessName!.isNotEmpty);

      final primaryOfferDone = freshSetup != null
          ? (freshSetup['primaryOfferSet'] == true)
          : (_userState.primaryMicroNicheId != null && _userState.primaryMicroNicheId!.isNotEmpty);

      final interestsDone = freshSetup != null
          ? (freshSetup['interestsSet'] == true)
          : (_userState.baselineDemandIds.isNotEmpty);

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: false,
        userName: _userState.username ?? _userState.businessName,
        businessName: _userState.businessName,
        avatarId: _userState.avatarId,
        contactsPermissionGranted: currentPerms.isContactsGranted,
        notificationsPermissionGranted: currentPerms.isNotificationGranted,
        profileCompleted: profileDone,
        primaryOfferSet: primaryOfferDone,
        interestsSet: interestsDone,
        contactGain: freshContactGain ?? state.contactGain,
        spotlight: freshSpotlight ?? state.spotlight,
      );

      _recalculateSetupSteps();

      // Save fresh data to local cache
      if (freshContactGain != null) {
        await HomeCacheService.saveContactGain(freshContactGain);
      }
      if (freshSpotlight != null) {
        await HomeCacheService.saveSpotlight(freshSpotlight);
      }
      if (freshSetup != null) {
        await HomeCacheService.saveSetupStatus(freshSetup);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: true,
        errorMessage: 'Unable to reach BizSquare network. Showing cached data.',
      );
    }
  }

  void _recalculateSetupSteps() {
    int completed = 0;
    if (state.profileCompleted) completed++;
    if (state.primaryOfferSet) completed++;
    if (state.interestsSet) completed++;
    if (state.contactsPermissionGranted) completed++;
    if (state.notificationsPermissionGranted) completed++;

    state = state.copyWith(completedSetupSteps: completed);
  }

  /// WhatsApp Spotlight Participation
  Future<bool> participateInCurrentSpotlight() async {
    final campaignId = state.spotlight?.campaignId;
    if (campaignId == null) return false;

    final success = await _spotlightService.participate(campaignId);
    if (success) {
      // Update local state optimistically
      final updatedSpotlight = state.spotlight?.copyWith(
        hasParticipated: true,
        participantCount: (state.spotlight?.participantCount ?? 0) + 1,
      );
      state = state.copyWith(spotlight: updatedSpotlight);
    }
    return success;
  }
}
