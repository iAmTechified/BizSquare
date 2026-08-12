import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/spotlight_model.dart';

final spotlightCacheServiceProvider = Provider<SpotlightCacheService>((ref) {
  return SpotlightCacheService();
});

class SpotlightCacheService {
  final FlutterSecureStorage _storage;
  static const _keyCurrentSpotlight = 'spotlight_cached_current';
  static const _keySubmissionDraft = 'spotlight_submission_draft';

  SpotlightCacheService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Caches the latest fetched Spotlight state
  Future<void> cacheCurrentSpotlight(SpotlightCurrentModel model) async {
    try {
      await _storage.write(
        key: _keyCurrentSpotlight,
        value: jsonEncode(model.toJson()),
      );
    } catch (_) {}
  }

  /// Retrieves the cached Spotlight state for offline viewing
  Future<SpotlightCurrentModel?> getCachedCurrentSpotlight() async {
    try {
      final jsonStr = await _storage.read(key: _keyCurrentSpotlight);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return SpotlightCurrentModel.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  /// Saves local draft of an unfinished submission
  Future<void> saveDraft(SpotlightSubmissionDraft draft) async {
    try {
      await _storage.write(
        key: _keySubmissionDraft,
        value: jsonEncode(draft.toJson()),
      );
    } catch (_) {}
  }

  /// Retrieves local submission draft
  Future<SpotlightSubmissionDraft?> getDraft() async {
    try {
      final jsonStr = await _storage.read(key: _keySubmissionDraft);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return SpotlightSubmissionDraft.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  /// Clears draft on successful submission
  Future<void> clearDraft() async {
    try {
      await _storage.delete(key: _keySubmissionDraft);
    } catch (_) {}
  }
}
