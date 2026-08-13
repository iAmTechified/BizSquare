import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state_model.dart';
import '../services/home_service.dart';
import '../services/spotlight_service.dart';
import '../services/home_cache_service.dart';
import 'auth_state_provider.dart';
import 'permission_state_provider.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, HomeState>((ref) {
  final homeService = ref.read(homeServiceProvider);
  final spotlightService = ref.read(spotlightServiceProvider);
  return HomeStateNotifier(homeService, spotlightService, ref);
});

class HomeStateNotifier extends StateNotifier<HomeState> {
  final HomeService _homeService;
  final SpotlightService _spotlightService;
  final Ref _ref;

  HomeStateNotifier(
    this._homeService,
    this._spotlightService,
    this._ref,
  ) : super(_buildInitialState(_ref)) {
    loadHomeData();
  }

  static HomeState _buildInitialState(Ref ref) {
    final userState = ref.read(userStateProvider);
    final permState = ref.read(permissionStateProvider);
    return HomeState(
      userName: userState.username ?? userState.businessName,
      businessName: userState.businessName,
      avatarId: userState.avatarId,
      contactsPermissionGranted: permState.isContactsGranted,
      notificationsPermissionGranted: permState.isNotificationGranted,
    );
  }

  /// Initial load: Instant cache load + Silent background refresh
  Future<void> loadHomeData() async {
    final userState = _ref.read(userStateProvider);

    // 1. Load cached data first for instant UI response
    final cachedContactGain = await HomeCacheService.getCachedContactGain();
    final cachedSpotlight = await HomeCacheService.getCachedSpotlight();
    final cachedSetup = await HomeCacheService.getCachedSetupStatus();

    if (!mounted) return;

    if (cachedContactGain != null || cachedSpotlight != null) {
      state = state.copyWith(
        contactGain: cachedContactGain,
        spotlight: cachedSpotlight,
        profileCompleted: cachedSetup?['profileCompleted'] ?? (userState.businessName != null),
        primaryOfferSet: cachedSetup?['primaryOfferSet'] ?? (userState.primaryMicroNicheId != null),
        interestsSet: cachedSetup?['interestsSet'] ?? (userState.baselineDemandIds.isNotEmpty),
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
      if (!mounted) return;
      final currentPerms = _ref.read(permissionStateProvider);
      final userState = _ref.read(userStateProvider);

      final results = await Future.wait([
        _homeService.getContactGainSummary().then<dynamic>((v) => v).catchError((_) => null),
        _spotlightService.getCurrentSpotlight().then<dynamic>((v) => v).catchError((_) => null),
        _homeService.getUserSetupStatus().then<dynamic>((v) => v).catchError((_) => null),
      ]);

      if (!mounted) return;

      final freshContactGain = results[0];
      final freshSpotlight = results[1];
      final freshSetup = results[2];

      final profileDone = freshSetup != null
          ? (freshSetup['profileCompleted'] == true)
          : (userState.businessName != null && userState.businessName!.isNotEmpty);

      final primaryOfferDone = freshSetup != null
          ? (freshSetup['primaryOfferSet'] == true)
          : (userState.primaryMicroNicheId != null && userState.primaryMicroNicheId!.isNotEmpty);

      final interestsDone = freshSetup != null
          ? (freshSetup['interestsSet'] == true)
          : (userState.baselineDemandIds.isNotEmpty);

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: false,
        userName: userState.username ?? userState.businessName,
        businessName: userState.businessName,
        avatarId: userState.avatarId,
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
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: true,
        errorMessage: 'Unable to reach BizSquare community. Showing cached data.',
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
    if (!mounted) return success;

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
