import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSyncService {
  Future<void> syncMatchedContacts(List<dynamic> matches) async {
    for (var match in matches) {
      final contact = Contact(
        name: Name(
          first: match['display_name'] ?? 'BizSquare',
          last: match['niche_name'] ?? '',
        ),
      );
      // Contact insertion stub
      _dummyLog(contact);
    }
  }

  void _dummyLog(Contact c) {}
}
