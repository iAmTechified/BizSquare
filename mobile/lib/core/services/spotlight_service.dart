import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spotlight_model.dart';
import 'api_service.dart';

final spotlightServiceProvider = Provider<SpotlightService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return SpotlightService(api);
});

class SpotlightService {
  final ApiService _api;

  SpotlightService(this._api);

  /// Fetches the active Spotlight campaign and turn status
  Future<SpotlightCurrentModel> getCurrentSpotlight() async {
    try {
      final response = await _api.dio.get('/spotlight/current');
      if (response.data != null && response.data['data'] != null) {
        return SpotlightCurrentModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
    } on DioException catch (_) {
      rethrow;
    }
    return const SpotlightCurrentModel(
      isMyTurn: false,
      targetParticipants: 48,
      participantCount: 0,
      hasParticipated: false,
      startDate: '',
      endDate: '',
    );
  }

  /// Records user participation (shared to WhatsApp status)
  Future<bool> participate(String campaignId) async {
    try {
      final response = await _api.dio.post(
        '/spotlight/participate',
        data: {'campaignId': campaignId},
      );
      return response.data != null && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Sets content for user's own Spotlight campaign
  Future<bool> setMyContent({
    required String title,
    required String promoText,
    required String caption,
    String? flyerUrl,
  }) async {
    try {
      final response = await _api.dio.post(
        '/spotlight/my-content',
        data: {
          'title': title,
          'promoText': promoText,
          'caption': caption,
          'flyerUrl': flyerUrl,
        },
      );
      return response.data != null && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches Spotlight History (Mine & Others)
  Future<({List<SpotlightHistoryItem> mine, List<SpotlightHistoryItem> others})> getHistory() async {
    try {
      final response = await _api.dio.get('/spotlight/history');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final mineList = (data['mine'] as List<dynamic>? ?? [])
            .map((e) => SpotlightHistoryItem.fromJsonMine(e as Map<String, dynamic>))
            .toList();
        final othersList = (data['others'] as List<dynamic>? ?? [])
            .map((e) => SpotlightHistoryItem.fromJsonOthers(e as Map<String, dynamic>))
            .toList();
        return (mine: mineList, others: othersList);
      }
    } catch (_) {}
    return (mine: <SpotlightHistoryItem>[], others: <SpotlightHistoryItem>[]);
  }
}
