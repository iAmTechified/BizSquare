import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/spotlight_model.dart';
import '../services/spotlight_service.dart';
import '../services/spotlight_cache_service.dart';

class SpotlightState {
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;
  final SpotlightCurrentModel? spotlight;
  final SpotlightSubmissionDraft? draft;
  final bool isSubmitting;
  final bool submissionSuccess;
  final String? submissionMessage;
  final List<SpotlightHistoryItem> historyMine;
  final List<SpotlightHistoryItem> historyOthers;
  final bool isLoadingHistory;

  const SpotlightState({
    this.isLoading = false,
    this.isOffline = false,
    this.errorMessage,
    this.spotlight,
    this.draft,
    this.isSubmitting = false,
    this.submissionSuccess = false,
    this.submissionMessage,
    this.historyMine = const [],
    this.historyOthers = const [],
    this.isLoadingHistory = false,
  });

  SpotlightState copyWith({
    bool? isLoading,
    bool? isOffline,
    String? errorMessage,
    SpotlightCurrentModel? spotlight,
    SpotlightSubmissionDraft? draft,
    bool? isSubmitting,
    bool? submissionSuccess,
    String? submissionMessage,
    List<SpotlightHistoryItem>? historyMine,
    List<SpotlightHistoryItem>? historyOthers,
    bool? isLoadingHistory,
  }) {
    return SpotlightState(
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      spotlight: spotlight ?? this.spotlight,
      draft: draft ?? this.draft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      submissionMessage: submissionMessage,
      historyMine: historyMine ?? this.historyMine,
      historyOthers: historyOthers ?? this.historyOthers,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

class SpotlightStateNotifier extends StateNotifier<SpotlightState> {
  final SpotlightService _service;
  final SpotlightCacheService _cache;
  final _uuid = const Uuid();

  SpotlightStateNotifier(this._service, this._cache) : super(const SpotlightState()) {
    loadSpotlight();
    loadDraft();
  }

  /// Initial load and cache hydration
  Future<void> loadSpotlight() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // 1. Try local cache first for instant rendering / offline mode
    final cached = await _cache.getCachedCurrentSpotlight();
    if (cached != null) {
      state = state.copyWith(spotlight: cached, isLoading: false);
    }

    // 2. Fetch live data from backend
    try {
      final liveData = await _service.getCurrentSpotlight();
      await _cache.cacheCurrentSpotlight(liveData);
      state = state.copyWith(
        isLoading: false,
        isOffline: false,
        errorMessage: null,
        spotlight: liveData,
      );
    } catch (e) {
      if (state.spotlight == null) {
        state = state.copyWith(
          isLoading: false,
          isOffline: true,
          errorMessage: 'Could not connect to Spotlight. Please check your internet connection.',
        );
      } else {
        // We have cached data
        state = state.copyWith(isLoading: false, isOffline: true);
      }
    }
  }

  /// Refresh triggered by user gesture or lifecycle event
  Future<void> refresh() async {
    try {
      final liveData = await _service.getCurrentSpotlight();
      await _cache.cacheCurrentSpotlight(liveData);
      state = state.copyWith(
        isOffline: false,
        errorMessage: null,
        spotlight: liveData,
      );
    } catch (_) {
      state = state.copyWith(isOffline: true);
    }
  }

  /// Hydrates draft from cache
  Future<void> loadDraft() async {
    final draft = await _cache.getDraft();
    if (draft != null) {
      state = state.copyWith(draft: draft);
    }
  }

  /// Saves local draft of an unfinished submission
  Future<void> saveDraft({
    required String title,
    required String promoText,
    required String caption,
    String? flyerUrl,
  }) async {
    final draft = SpotlightSubmissionDraft(
      title: title,
      promoText: promoText,
      caption: caption,
      flyerUrl: flyerUrl,
      lastSaved: DateTime.now(),
    );
    await _cache.saveDraft(draft);
    state = state.copyWith(draft: draft);
  }

  /// Submits Spotlight campaign (idempotent, safe against duplicates)
  Future<bool> submitSpotlight({
    required String title,
    required String promoText,
    required String caption,
    String? flyerUrl,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(
      isSubmitting: true,
      submissionSuccess: false,
      submissionMessage: null,
      errorMessage: null,
    );

    final idempotencyKey = _uuid.v4();

    try {
      final result = await _service.submitSpotlight(
        title: title,
        promoText: promoText,
        caption: caption,
        flyerUrl: flyerUrl,
        idempotencyKey: idempotencyKey,
      );

      if (result.success) {
        await _cache.clearDraft();
        await refresh();
        state = state.copyWith(
          isSubmitting: false,
          submissionSuccess: true,
          submissionMessage: result.message,
          draft: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          submissionSuccess: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionSuccess: false,
        errorMessage: 'Failed to submit Spotlight. Please try again.',
      );
      return false;
    }
  }

  /// Records WhatsApp Status share participation
  Future<bool> participateInCurrentSpotlight() async {
    final spotlight = state.spotlight;
    if (spotlight == null || spotlight.campaignId == null) return false;

    final success = await _service.participate(spotlight.campaignId!);
    if (success) {
      // Optimistically update participant count and status
      final updated = spotlight.copyWith(
        hasParticipated: true,
        participantCount: spotlight.participantCount + 1,
      );
      state = state.copyWith(spotlight: updated);
      await _cache.cacheCurrentSpotlight(updated);
    }
    return success;
  }

  /// Fetches history for Mine and Others tabs
  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final history = await _service.getHistory();
      state = state.copyWith(
        isLoadingHistory: false,
        historyMine: history.mine,
        historyOthers: history.others,
      );
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }
}

final spotlightStateProvider =
    StateNotifierProvider<SpotlightStateNotifier, SpotlightState>((ref) {
  final service = ref.watch(spotlightServiceProvider);
  final cache = ref.watch(spotlightCacheServiceProvider);
  return SpotlightStateNotifier(service, cache);
});
