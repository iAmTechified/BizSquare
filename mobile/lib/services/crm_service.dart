import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class CrmService {
  final Dio _dio;
  CrmService(this._dio);

  Future<List<Map<String, dynamic>>> getContacts() async {
    // Simulated API call using _dio
    return [
      {'id': '1', 'network_name': 'Emeka Okafor', 'network_phone': '+234 801 234 5678', 'lead_grade': 'A', 'label': 'Customer'},
      {'id': '2', 'network_name': 'Ngozi Adichie', 'network_phone': '+234 802 345 6789', 'lead_grade': 'B', 'label': 'Warm Lead'},
    ];
  }

  Future<void> updateContact(String id, Map<String, dynamic> data) async {
    debugPrint('Updating contact $id with $data via _dio');
    await _dio.put('/crm/contacts/$id', data: data);
  }
}
