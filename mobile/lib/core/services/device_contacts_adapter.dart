import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';
import '../utils/phone_normalizer.dart';

class RawDeviceContact {
  final String id;
  final String displayName;
  final String firstName;
  final String lastName;
  final List<String> phones;
  final List<String> canonicalPhones;
  final List<String> emails;
  final String? company;

  const RawDeviceContact({
    required this.id,
    required this.displayName,
    this.firstName = '',
    this.lastName = '',
    this.phones = const [],
    this.canonicalPhones = const [],
    this.emails = const [],
    this.company,
  });
}

class DeviceContactsAdapter {
  /// Checks permission status for contacts
  static Future<bool> hasPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking contacts permission: $e');
      return false;
    }
  }

  /// Requests permission from the OS
  static Future<bool> requestPermission() async {
    try {
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting contacts permission: $e');
      return false;
    }
  }

  /// Opens application settings when permanently denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Fetches all device contacts with properties
  static Future<List<RawDeviceContact>> fetchDeviceContacts() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) return [];

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.email,
          ContactProperty.organization,
        },
      );

      return contacts.map((c) {
        final phones = c.phones.map((p) => p.number.trim()).where((p) => p.isNotEmpty).toList();
        final canonical = phones.map((p) => PhoneNormalizer.normalize(p)).where((p) => p.isNotEmpty).toSet().toList();
        final emails = c.emails.map((e) => e.address.trim()).where((e) => e.isNotEmpty).toList();
        final displayName = (c.displayName != null && c.displayName!.isNotEmpty)
            ? c.displayName!
            : '${c.name?.first ?? ""} ${c.name?.last ?? ""}'.trim();

        return RawDeviceContact(
          id: c.id ?? '',
          displayName: displayName.isNotEmpty ? displayName : 'Unnamed Contact',
          firstName: c.name?.first ?? '',
          lastName: c.name?.last ?? '',
          phones: phones,
          canonicalPhones: canonical,
          emails: emails,
          company: c.organizations.isNotEmpty ? c.organizations.first.name : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error reading device contacts: $e');
      return [];
    }
  }

  /// Inserts a new contact to device address book
  static Future<bool> insertContact({
    required String fullName,
    required String phoneNumber,
    String? company,
  }) async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) return false;

      final newContact = Contact(
        name: Name(first: fullName),
        phones: [Phone(number: phoneNumber)],
        organizations: company != null ? [Organization(name: company)] : const [],
      );

      await FlutterContacts.create(newContact);
      return true;
    } catch (e) {
      debugPrint('Error inserting contact to device: $e');
      return false;
    }
  }
}
