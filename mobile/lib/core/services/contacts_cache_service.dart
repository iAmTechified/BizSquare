import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/unified_contact_model.dart';

class ContactsCacheService {
  static const _storage = FlutterSecureStorage();
  static const _kSquareContactsKey = 'bizsquare_cached_square_contacts';
  static const _kLabelsKey = 'bizsquare_cached_labels';

  /// Save Square Contacts to cache
  static Future<void> saveSquareContacts(List<UnifiedContactModel> contacts) async {
    try {
      final jsonList = contacts.map((c) => c.toJson()).toList();
      await _storage.write(key: _kSquareContactsKey, value: jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error caching square contacts: $e');
    }
  }

  /// Read cached Square Contacts
  static Future<List<UnifiedContactModel>> loadCachedSquareContacts() async {
    try {
      final data = await _storage.read(key: _kSquareContactsKey);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data) as List;
        return decoded.map((item) => UnifiedContactModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached square contacts: $e');
    }
    return [];
  }

  /// Save labels to cache
  static Future<void> saveLabels(List<ContactLabelModel> labels) async {
    try {
      final jsonList = labels.map((l) => l.toJson()).toList();
      await _storage.write(key: _kLabelsKey, value: jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error caching labels: $e');
    }
  }

  /// Load cached labels
  static Future<List<ContactLabelModel>> loadCachedLabels() async {
    try {
      final data = await _storage.read(key: _kLabelsKey);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data) as List;
        return decoded.map((item) => ContactLabelModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached labels: $e');
    }
    return [];
  }
}
