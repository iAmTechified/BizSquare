import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/interest_taxonomy_model.dart';
import '../models/wall_content_model.dart';
import '../models/interest_demand_model.dart';
import 'api_service.dart';

final interestServiceProvider = Provider<InterestService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return InterestService(api);
});

class InterestService {
  final ApiService _apiService;
  static const _uuid = Uuid();

  InterestService(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Fetch all active interest taxonomies
  Future<List<InterestTaxonomyModel>> fetchTaxonomies() async {
    try {
      final response = await _dio.get('/interest/taxonomies');
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['taxonomies'] as List<dynamic>?) ?? [];
        return list.map((t) => InterestTaxonomyModel.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Fetch user baseline interests
  Future<List<Map<String, dynamic>>> fetchBaselineInterests() async {
    try {
      final response = await _dio.get('/interest/baseline');
      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data['baseline'] ?? []);
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Update baseline interests
  Future<bool> updateBaselineInterests(List<String> taxonomyIds) async {
    try {
      final response = await _dio.put(
        '/interest/baseline',
        data: {'taxonomyIds': taxonomyIds},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch daily interactive wall session
  Future<WallSessionModel?> fetchDailyWallSession({int targetCount = 5}) async {
    try {
      final response = await _dio.get(
        '/interest/wall/session',
        queryParameters: {'targetCount': targetCount},
      );
      if (response.statusCode == 200 && response.data != null) {
        return WallSessionModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  /// Submit wall interaction with UUID idempotency key
  Future<bool> submitWallInteraction({
    String? eventId,
    String? sessionId,
    required String contentId,
    required String format,
    required String optionId,
    required String interactionType,
    int dwellMs = 0,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final key = eventId ?? _uuid.v4();
      final response = await _dio.post(
        '/interest/wall/interaction',
        data: {
          'eventId': key,
          'sessionId': sessionId,
          'contentId': contentId,
          'format': format,
          'optionId': optionId,
          'interactionType': interactionType,
          'dwellMs': dwellMs,
          'metadata': metadata ?? {},
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Complete daily wall session
  Future<bool> completeDailyWallSession(String sessionId) async {
    try {
      final response = await _dio.post(
        '/interest/wall/session/complete',
        data: {'sessionId': sessionId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch structured current demand profile
  Future<UserCurrentDemandModel?> fetchCurrentDemand() async {
    try {
      final response = await _dio.get('/interest/demand/current');
      if (response.statusCode == 200 && response.data != null) {
        return UserCurrentDemandModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }
}
