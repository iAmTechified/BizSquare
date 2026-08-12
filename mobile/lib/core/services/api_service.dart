import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final Dio _dio;

  // Android emulator connects to host at 10.0.2.2; desktop/web connects to localhost
  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  ApiService({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Step 3: Atomic verification and account registration
  Future<Map<String, dynamic>> verifyAndRegister({
    required String code,
    required String phoneNumber,
    required String businessName,
    String? fullName,
    required int avatarId,
    required List<String> microNicheIds,
    required String primaryMicroNicheId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-and-register',
        data: {
          'code': code.trim().toUpperCase(),
          'phoneNumber': phoneNumber.trim(),
          'businessName': businessName.trim(),
          'fullName': fullName?.trim() ?? businessName.trim(),
          'avatarId': avatarId,
          'microNicheIds': microNicheIds,
          'primaryMicroNicheId': primaryMicroNicheId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        setAuthToken(data['token'] as String);
      }
      return data;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? e.message ?? 'Verification failed';
      final code = e.response?.data?['code'] ?? 'UNKNOWN_ERROR';
      throw ApiException(message: message.toString(), code: code.toString());
    }
  }

  /// Steps 4+5: Complete onboarding with Security PIN and Baseline Demand
  Future<Map<String, dynamic>> completeOnboarding({
    required String username,
    required String pin,
    required List<String> interestMicroNicheIds,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/complete-onboarding',
        data: {
          'username': username.trim(),
          'pin': pin.trim(),
          'interestMicroNicheIds': interestMicroNicheIds,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? e.message ?? 'Failed to complete onboarding';
      final code = e.response?.data?['code'] ?? 'UNKNOWN_ERROR';
      throw ApiException(message: message.toString(), code: code.toString());
    }
  }

  /// Login with phone number and PIN
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    String? pin,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'phoneNumber': phoneNumber.trim(),
          if (pin != null && pin.isNotEmpty) 'pin': pin.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        setAuthToken(data['token'] as String);
      }
      return data;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? e.message ?? 'Login failed';
      final code = e.response?.data?['code'] ?? 'UNKNOWN_ERROR';
      throw ApiException(message: message.toString(), code: code.toString());
    }
  }

  /// Real-time username availability check
  Future<bool> checkUsernameAvailable(String username) async {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    if (clean.length < 3) return false;

    try {
      final response = await _dio.get('/auth/username-available/$clean');
      return response.data['available'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Record Daily Wall swipe as Dynamic Demand (~14-day decay)
  Future<void> submitDynamicDemand({
    required String microNicheId,
    required String interactionType,
  }) async {
    try {
      await _dio.post(
        '/demand/dynamic',
        data: {
          'microNicheId': microNicheId,
          'interactionType': interactionType,
        },
      );
    } catch (e) {
      debugPrint('Failed to submit dynamic demand: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String code;

  ApiException({required this.message, this.code = 'UNKNOWN_ERROR'});

  @override
  String toString() => message;
}
