import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(dioProvider)));

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String phone, String password) async {
    // Simulated API call using _dio
    final res = await _dio.get('/health').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {}));
    return {'token': 'mock_token_123', 'user': {'id': '1', 'phone': phone}, 'status': res.statusCode};
  }

  Future<Map<String, dynamic>> register(String name, String phone, String email, String password) async {
    return {'message': 'Passcode generated'};
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    return {'token': 'mock_token_123', 'user': {'id': '1', 'phone': phone}};
  }
}
