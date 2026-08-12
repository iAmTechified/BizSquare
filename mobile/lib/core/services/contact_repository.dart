import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/unified_contact_model.dart';
import '../utils/phone_normalizer.dart';
import 'device_contacts_adapter.dart';
import 'contacts_cache_service.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});

class ContactRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String _baseUrl = 'http://localhost:8080/api/v1';

  ContactRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15))),
        _storage = storage ?? const FlutterSecureStorage();

  Future<Options> _getAuthHeaders() async {
    final token = await _storage.read(key: 'bizsquare_auth_token');
    return Options(headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  /// Fetches backend Square Contacts
  Future<List<UnifiedContactModel>> fetchSquareContacts({bool includeArchived = false}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '$_baseUrl/contacts',
        queryParameters: {'include_archived': includeArchived.toString()},
        options: headers,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['contacts'] as List? ?? [])
            .map((item) => UnifiedContactModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!includeArchived) {
          await ContactsCacheService.saveSquareContacts(list);
        }
        return list;
      }
    } catch (e) {
      debugPrint('Error fetching backend square contacts: $e');
    }
    return await ContactsCacheService.loadCachedSquareContacts();
  }

  /// Fetches real device contacts and joins with Square metadata
  Future<List<UnifiedContactModel>> fetchUnifiedDeviceContacts(List<UnifiedContactModel> squareContacts) async {
    final rawDeviceContacts = await DeviceContactsAdapter.fetchDeviceContacts();

    // Map square contacts by canonical phone for fast O(1) identity lookup
    final squareByPhone = <String, UnifiedContactModel>{};
    for (final sc in squareContacts) {
      if (sc.canonicalPhone.isNotEmpty) {
        squareByPhone[sc.canonicalPhone] = sc;
      }
    }

    final unifiedList = <UnifiedContactModel>[];
    final matchedSquareIds = <String>{};

    for (final dc in rawDeviceContacts) {
      final canonical = dc.canonicalPhones.isNotEmpty ? dc.canonicalPhones.first : '';
      final squareMatch = canonical.isNotEmpty ? squareByPhone[canonical] : null;

      if (squareMatch != null) {
        matchedSquareIds.add(squareMatch.id);
        unifiedList.add(squareMatch.copyWith(
          deviceContactId: dc.id,
          fullName: dc.displayName.isNotEmpty ? dc.displayName : squareMatch.fullName,
        ));
      } else {
        unifiedList.add(UnifiedContactModel(
          id: 'dev_${dc.id}',
          deviceContactId: dc.id,
          fullName: dc.displayName,
          businessName: dc.company,
          phoneNumber: dc.phones.isNotEmpty ? dc.phones.first : '',
          canonicalPhone: canonical,
          isSquareContact: false,
          isStarred: false,
          isArchived: false,
          labels: [],
          syncState: ContactSyncState.synced,
        ));
      }
    }

    // Sort alphabetically by default
    unifiedList.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return unifiedList;
  }

  /// Detects potential duplicates in contact dataset
  List<DuplicateContactPair> detectDuplicates(List<UnifiedContactModel> contacts) {
    final duplicates = <DuplicateContactPair>[];
    final phoneMap = <String, List<UnifiedContactModel>>{};
    final nameMap = <String, List<UnifiedContactModel>>{};

    for (final c in contacts) {
      if (c.canonicalPhone.isNotEmpty) {
        phoneMap.putIfAbsent(c.canonicalPhone, () => []).add(c);
      }
      final cleanName = c.displayName.trim().toLowerCase();
      if (cleanName.isNotEmpty && cleanName.length > 2) {
        nameMap.putIfAbsent(cleanName, () => []).add(c);
      }
    }

    // Check same phone duplicates
    for (final entry in phoneMap.entries) {
      if (entry.value.length > 1) {
        final primary = entry.value.firstWhere((c) => c.isSquareContact, orElse: () => entry.value.first);
        for (final dup in entry.value) {
          if (dup.id != primary.id) {
            duplicates.add(DuplicateContactPair(
              primary: primary,
              duplicate: dup,
              reason: 'Identical phone number (${PhoneNormalizer.formatDisplay(entry.key)})',
            ));
          }
        }
      }
    }

    return duplicates;
  }

  /// Updates single contact
  Future<bool> updateContact({
    required String contactId,
    bool? isStarred,
    bool? isArchived,
    String? notes,
    List<String>? labels,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.put(
        '$_baseUrl/contacts/$contactId',
        data: {
          if (isStarred != null) 'isStarred': isStarred,
          if (isArchived != null) 'isArchived': isArchived,
          if (notes != null) 'notes': notes,
          if (labels != null) 'labels': labels,
        },
        options: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating contact: $e');
      return false;
    }
  }

  /// Bulk updates
  Future<bool> bulkUpdate({
    required List<String> contactIds,
    required String action,
    String? labelName,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '$_baseUrl/contacts/bulk',
        data: {
          'contactIds': contactIds,
          'action': action,
          if (labelName != null) 'labelName': labelName,
        },
        options: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error executing bulk update: $e');
      return false;
    }
  }

  /// Merge contacts
  Future<bool> mergeContacts(String primaryId, String duplicateId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '$_baseUrl/contacts/merge',
        data: {
          'primaryContactId': primaryId,
          'duplicateContactId': duplicateId,
        },
        options: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error merging contacts: $e');
      return false;
    }
  }

  /// Labels
  Future<List<ContactLabelModel>> fetchLabels() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get('$_baseUrl/contacts/labels', options: headers);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['labels'] as List? ?? [])
            .map((item) => ContactLabelModel.fromJson(item as Map<String, dynamic>))
            .toList();
        await ContactsCacheService.saveLabels(list);
        return list;
      }
    } catch (e) {
      debugPrint('Error fetching labels: $e');
    }
    return await ContactsCacheService.loadCachedLabels();
  }

  Future<ContactLabelModel?> createLabel(String name, {String color = '#0058FF'}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '$_baseUrl/contacts/labels',
        data: {'name': name, 'color': color},
        options: headers,
      );
      if (response.statusCode == 200 && response.data?['label'] != null) {
        return ContactLabelModel.fromJson(response.data['label']);
      }
    } catch (e) {
      debugPrint('Error creating label: $e');
    }
    return null;
  }

  Future<bool> deleteLabel(String labelId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete('$_baseUrl/contacts/labels/$labelId', options: headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting label: $e');
      return false;
    }
  }

  Future<bool> acknowledgeDeviceSync(List<String> userIds, String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '$_baseUrl/contacts/sync-device',
        data: {'contactUserIds': userIds, 'status': status},
        options: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error acknowledging device sync: $e');
      return false;
    }
  }
}
