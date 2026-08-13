import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state_provider.dart';
import '../data/micro_niche_taxonomy.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref: ref);
});

class ApiService {
  late final Dio _dio;
  final Ref? _ref;

  static const String liveProductionUrl = 'https://bizsquare-backend.onrender.com/api/v1';

  static String get defaultBaseUrl {
    return liveProductionUrl;
  }

  ApiService({String? baseUrl, Ref? ref}) : _ref = ref {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add 401 session expiry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.response?.statusCode == 401 && _ref != null) {
            debugPrint('[ApiService] 401 Unauthorized — clearing session and logging out.');
            // Fire-and-forget logout; GoRouter redirect guard picks up the state change
            _ref.read(userStateProvider.notifier).logout();
          }
          handler.next(error);
        },
      ),
    );

    // Add Dio LogInterceptor for live request/response inspection
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ),
    );
  }

  Dio get dio => _dio;

  void setAuthToken(String? token) {
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
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
          'code': code,
          'phoneNumber': phoneNumber,
          'businessName': businessName,
          'fullName': fullName ?? businessName,
          'avatarId': avatarId,
          'microNicheIds': microNicheIds,
          'primaryMicroNicheId': primaryMicroNicheId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'] as String
          : e.message ?? 'Verification failed';
      final errCode = data is Map && data['code'] != null
          ? data['code'] as String
          : 'VERIFICATION_ERROR';
      throw ApiException(message: msg, code: errCode, statusCode: e.response?.statusCode);
    }
  }

  /// Step 5: Finalize user credentials (PIN, custom username, baseline interests)
  Future<Map<String, dynamic>> completeOnboarding({
    required String username,
    required String pin,
    required List<String> interestMicroNicheIds,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/complete-onboarding',
        data: {
          'username': username,
          'pin': pin,
          'interestMicroNicheIds': interestMicroNicheIds,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'] as String
          : e.message ?? 'Onboarding failed';
      final errCode = data is Map && data['code'] != null
          ? data['code'] as String
          : 'ONBOARDING_ERROR';
      throw ApiException(message: msg, code: errCode, statusCode: e.response?.statusCode);
    }
  }

  /// Direct Login with phone and PIN
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'phoneNumber': phoneNumber,
          'pin': pin,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'] as String
          : e.message ?? 'Login failed';
      final errCode = data is Map && data['code'] != null
          ? data['code'] as String
          : 'LOGIN_ERROR';
      throw ApiException(message: msg, code: errCode, statusCode: e.response?.statusCode);
    }
  }

  /// Check if custom username is available
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final clean = username.trim().replaceAll('@', '');
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

  /// Fetch dynamic taxonomy from the backend
  Future<List<Category>> fetchTaxonomy() async {
    try {
      final response = await _dio.get('/taxonomy/categories');
      final data = response.data as List<dynamic>;
      return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'] as String
          : e.message ?? 'Failed to fetch taxonomy';
      final errCode = data is Map && data['code'] != null
          ? data['code'] as String
          : 'TAXONOMY_ERROR';
      throw ApiException(message: msg, code: errCode, statusCode: e.response?.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  ApiException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
  });

  @override
  String toString() => message;
}
