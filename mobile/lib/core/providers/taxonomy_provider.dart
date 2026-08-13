import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/micro_niche_taxonomy.dart';
import '../services/api_service.dart';

// ─── Cache Key ────────────────────────────────────────────────────────────────
const _kCacheKey = 'taxonomy_cache_v1';
const _kCacheTimestampKey = 'taxonomy_cache_ts_v1';
const _kCacheTtlHours = 12;

// ─── Provider ─────────────────────────────────────────────────────────────────
final taxonomyProvider = AsyncNotifierProvider<TaxonomyNotifier, List<Category>>(
  TaxonomyNotifier.new,
);

class TaxonomyNotifier extends AsyncNotifier<List<Category>> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<List<Category>> build() async {
    return _loadWithCache();
  }

  // ── Public refresh (called from retry button) ────────────────────────────
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFromNetwork(forceRefresh: true));
  }

  // ── Main loading logic ────────────────────────────────────────────────────
  Future<List<Category>> _loadWithCache() async {
    // 1. Try to serve from valid cache first (instant, no spinner for repeat visits)
    final cached = await _readCache();
    if (cached != null) {
      // Refresh in background after serving cache so next open is up-to-date
      _fetchFromNetwork(forceRefresh: false).then((fresh) {
        if (state.hasValue) state = AsyncValue.data(fresh);
      }).catchError((_) {});
      return cached;
    }

    // 2. No valid cache — fetch from network (shows shimmer)
    return _fetchFromNetwork(forceRefresh: true);
  }

  // ── Network fetch ─────────────────────────────────────────────────────────
  Future<List<Category>> _fetchFromNetwork({required bool forceRefresh}) async {
    final api = ref.read(apiServiceProvider);
    final categories = await api.fetchTaxonomy();

    if (categories.isEmpty) {
      throw Exception('The server returned an empty taxonomy. Please try again later.');
    }

    // Persist to cache
    await _writeCache(categories);
    return categories;
  }

  // ── Cache read ────────────────────────────────────────────────────────────
  Future<List<Category>?> _readCache() async {
    try {
      final tsStr = await _storage.read(key: _kCacheTimestampKey);
      if (tsStr == null) return null;

      final ts = DateTime.tryParse(tsStr);
      if (ts == null) return null;

      final age = DateTime.now().difference(ts);
      if (age.inHours >= _kCacheTtlHours) return null; // expired

      final raw = await _storage.read(key: _kCacheKey);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Cache write ───────────────────────────────────────────────────────────
  Future<void> _writeCache(List<Category> categories) async {
    try {
      final encoded = jsonEncode(
        categories.map((c) => c.toJson()).toList(),
      );
      await _storage.write(key: _kCacheKey, value: encoded);
      await _storage.write(
        key: _kCacheTimestampKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  // ── Cache invalidation (call when admin updates taxonomy) ─────────────────
  Future<void> invalidateCache() async {
    try {
      await _storage.delete(key: _kCacheKey);
      await _storage.delete(key: _kCacheTimestampKey);
    } catch (_) {}
  }
}
