import 'package:flutter/foundation.dart';
import '../models/unified_contact_model.dart';
import 'device_contacts_adapter.dart';
import 'contact_repository.dart';

class ContactSyncEngine {
  final ContactRepository _repository;

  ContactSyncEngine(this._repository);

  /// Synchronizes unsynced Square Contacts into device address book
  Future<int> syncSquareContactsToDevice(List<UnifiedContactModel> squareContacts) async {
    final hasPerm = await DeviceContactsAdapter.hasPermission();
    if (!hasPerm) {
      debugPrint('Sync aborted: Contact permission not granted.');
      return 0;
    }

    int syncedCount = 0;
    final syncedUserIds = <String>[];

    final existingDeviceContacts = await DeviceContactsAdapter.fetchDeviceContacts();
    final existingCanonicalPhones = existingDeviceContacts
        .expand((c) => c.canonicalPhones)
        .toSet();

    for (final contact in squareContacts) {
      if (contact.canonicalPhone.isEmpty) continue;

      // Only insert if not already in phone address book
      if (!existingCanonicalPhones.contains(contact.canonicalPhone)) {
        final success = await DeviceContactsAdapter.insertContact(
          fullName: contact.fullName.isNotEmpty ? contact.fullName : (contact.businessName ?? 'BizSquare Contact'),
          phoneNumber: contact.phoneNumber,
          company: contact.businessName,
        );

        if (success) {
          syncedCount++;
          if (contact.userId != null) {
            syncedUserIds.add(contact.userId!);
          }
        }
      }
    }

    if (syncedUserIds.isNotEmpty) {
      // Notify backend that contacts are physically stored in device address book
      await _repository.acknowledgeDeviceSync(syncedUserIds, 'SYNCED');
    }

    return syncedCount;
  }
}
