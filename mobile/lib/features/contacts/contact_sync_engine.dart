import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';

final contactSyncEngineProvider = Provider((ref) => ContactSyncEngine(ref.watch(dioProvider)));

class ContactSyncEngine {
  final Dio _dio;
  static const String bizSquareTag = '[BizSquare_Network]';

  ContactSyncEngine(this._dio);

  Future<void> syncWeeklyBatch() async {
    final response = await _dio.get('/matches/current');
    final List matches = response.data['matches'] ?? [];
    await _purgeOldMatches();

    for (var match in matches) {
      final user = match['matched_user'];
      final fullName = user['full_name'] ?? 'BizSquare Match';

      await _dio.post('/matches/sync-status', data: {
        'matchId': match['id'],
        'status': 'synced',
        'contactName': fullName,
      });
    }
  }

  Future<void> _purgeOldMatches() async {
    // Contact purging stubbed
  }
}
