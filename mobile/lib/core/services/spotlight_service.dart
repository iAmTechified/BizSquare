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

  /// Fetches the server-authoritative active Spotlight campaign and turn status
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
      cycleStartDate: '',
      cycleEndDate: '',
      targetParticipants: 48,
      participantCount: 0,
      hasParticipated: false,
    );
  }

  /// Submits Spotlight campaign (idempotent)
  Future<({bool success, String? campaignId, String? submissionStatus, String message})> submitSpotlight({
    required String title,
    required String promoText,
    required String caption,
    String? flyerUrl,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _api.dio.post(
        '/spotlight/submit',
        data: {
          'title': title,
          'promoText': promoText,
          'caption': caption,
          'flyerUrl': flyerUrl,
          'idempotencyKey': idempotencyKey,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return (
          success: true,
          campaignId: response.data['campaignId'] as String?,
          submissionStatus: response.data['submissionStatus'] as String?,
          message: response.data['message'] as String? ?? 'Spotlight submitted successfully',
        );
      }
      return (
        success: false,
        campaignId: null,
        submissionStatus: null,
        message: response.data?['error'] as String? ?? 'Failed to submit Spotlight',
      );
    } on DioException catch (e) {
      return (
        success: false,
        campaignId: null,
        submissionStatus: null,
        message: e.response?.data?['error'] as String? ?? 'Network error submitting Spotlight',
      );
    }
  }

  /// Sets content for user's own Spotlight campaign (alias for submitSpotlight)
  Future<bool> setMyContent({
    required String title,
    required String promoText,
    required String caption,
    String? flyerUrl,
  }) async {
    final res = await submitSpotlight(
      title: title,
      promoText: promoText,
      caption: caption,
      flyerUrl: flyerUrl,
    );
    return res.success;
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

  /// Fetches list of authorized participants for a campaign
  Future<List<SpotlightParticipantModel>> getCampaignParticipants(String campaignId) async {
    try {
      final response = await _api.dio.get('/spotlight/campaign/$campaignId/participants');
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((e) => SpotlightParticipantModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
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
