import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import 'api_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileService(dio: apiService.dio);
});

class ProfileService {
  final Dio _dio;

  ProfileService({required Dio dio}) : _dio = dio;

  /// Fetches complete profile of authenticated user
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      final data = response.data;
      if (data['success'] == true && data['user'] != null) {
        return UserProfileModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Failed to parse user profile');
    } on DioException catch (e) {
      debugPrint('ProfileService getProfile error: $e');
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'] as String
          : 'Unable to load profile. Please check your internet connection.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  /// Fetches real setup completion flags
  Future<UserSetupStatusModel> getSetupStatus() async {
    try {
      final response = await _dio.get('/users/setup-status');
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return UserSetupStatusModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return const UserSetupStatusModel();
    } on DioException catch (e) {
      debugPrint('ProfileService getSetupStatus error: $e');
      return const UserSetupStatusModel();
    }
  }

  /// Updates profile identity details (business name, full name, avatar)
  Future<UserProfileModel> updateProfile({
    String? businessName,
    String? fullName,
    int? avatarId,
  }) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: {
          if (businessName != null) 'businessName': businessName.trim(),
          if (fullName != null) 'fullName': fullName.trim(),
          if (avatarId != null) 'avatarId': avatarId,
        },
      );
      final data = response.data;
      if (data['success'] == true && data['user'] != null) {
        // Fetch refreshed complete profile
        return await getProfile();
      }
      throw ApiException(message: 'Profile update failed');
    } on DioException catch (e) {
      debugPrint('ProfileService updateProfile error: $e');
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'] as String
          : 'Could not save profile changes. Please try again.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  /// Updates primary offer and secondary offers
  Future<List<UserSupplyNicheModel>> updateOffers({
    required String primaryMicroNicheId,
    required List<String> secondaryMicroNicheIds,
  }) async {
    try {
      final response = await _dio.put(
        '/users/offers',
        data: {
          'primaryMicroNicheId': primaryMicroNicheId,
          'secondaryMicroNicheIds': secondaryMicroNicheIds,
        },
      );
      final data = response.data;
      if (data['success'] == true && data['supplyNiches'] is List) {
        return (data['supplyNiches'] as List)
            .map((item) => UserSupplyNicheModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(message: 'Failed to update business offerings');
    } on DioException catch (e) {
      debugPrint('ProfileService updateOffers error: $e');
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'] as String
          : 'Could not save business offers. Please try again.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  /// Updates baseline explicit interests
  Future<void> updateBaselineInterests(List<String> taxonomyIds) async {
    try {
      await _dio.put(
        '/interest/baseline',
        data: {'taxonomyIds': taxonomyIds},
      );
    } on DioException catch (e) {
      debugPrint('ProfileService updateBaselineInterests error: $e');
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'] as String
          : 'Could not save interests. Please try again.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  /// Updates user's 4-digit PIN
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final response = await _dio.put(
        '/users/pin',
        data: {
          'currentPin': currentPin,
          'newPin': newPin,
        },
      );
      if (response.data['success'] != true) {
        throw ApiException(message: response.data['error'] ?? 'Failed to update PIN');
      }
    } on DioException catch (e) {
      debugPrint('ProfileService changePin error: $e');
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'] as String
          : 'Could not change PIN. Please check current PIN and try again.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  /// Deactivates user account
  Future<void> deactivateAccount() async {
    try {
      await _dio.delete('/users/me');
    } on DioException catch (e) {
      debugPrint('ProfileService deactivateAccount error: $e');
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'] as String
          : 'Could not deactivate account. Please try again.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }
}
