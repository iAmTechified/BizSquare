import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/unified_contact_model.dart';
import '../../../../core/services/device_contacts_adapter.dart';
import 'contact_card.dart';

class AllContactsTab extends StatelessWidget {
  final List<UnifiedContactModel> contacts;
  final bool hasPermission;
  final bool isPermanentlyDenied;
  final String? expandedContactId;
  final bool isSelectionMode;
  final Set<String> selectedContactIds;
  final Future<void> Function() onRefresh;
  final VoidCallback onRequestPermission;
  final void Function(String) onCardToggle;
  final void Function(UnifiedContactModel) onStarToggle;
  final void Function(UnifiedContactModel) onArchive;
  final void Function(String, bool?) onSelectToggle;
  final void Function(String) onLongPress;

  const AllContactsTab({
    super.key,
    required this.contacts,
    required this.hasPermission,
    required this.isPermanentlyDenied,
    this.expandedContactId,
    this.isSelectionMode = false,
    this.selectedContactIds = const {},
    required this.onRefresh,
    required this.onRequestPermission,
    required this.onCardToggle,
    required this.onStarToggle,
    required this.onArchive,
    required this.onSelectToggle,
    required this.onLongPress,
  });

  Map<String, List<UnifiedContactModel>> _groupAlphabetical(List<UnifiedContactModel> list) {
    final groups = <String, List<UnifiedContactModel>>{};
    for (final c in list) {
      final name = c.displayName.trim();
      final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '#';
      final key = RegExp(r'^[A-Z]$').hasMatch(firstLetter) ? firstLetter : '#';
      groups.putIfAbsent(key, () => []).add(c);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Permission Not Granted State
    if (!hasPermission) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedContact01,
                  color: Color(0xFF0058FF),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPermanentlyDenied ? 'Contact access is off' : 'Your contacts are waiting',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPermanentlyDenied
                  ? 'Enable contact access in your phone settings to view and manage your contacts inside BizSquare.'
                  : 'Allow BizSquare to access your contacts so we can display and manage your phone address book alongside your Square Contacts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isPermanentlyDenied
                    ? () => DeviceContactsAdapter.openSettings()
                    : onRequestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isPermanentlyDenied ? 'Open settings' : 'Allow access',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Empty Contacts State
    if (contacts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFF0058FF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          children: [
            Center(
              child: Text(
                'No contacts found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Your phone doesn\'t currently have any contacts available to BizSquare.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Alphabetical Contact List
    final grouped = _groupAlphabetical(contacts);
    final sortedKeys = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF0058FF),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final letter = sortedKeys[index];
          final letterContacts = grouped[letter]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 20, 6),
                child: Text(
                  letter,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0058FF),
                  ),
                ),
              ),
              ...letterContacts.map((contact) {
                return ContactCard(
                  contact: contact,
                  isExpanded: expandedContactId == contact.id,
                  isSelected: selectedContactIds.contains(contact.id),
                  isSelectionMode: isSelectionMode,
                  onTap: () => onCardToggle(contact.id),
                  onLongPress: () => onLongPress(contact.id),
                  onStarToggle: () => onStarToggle(contact),
                  onArchive: () => onArchive(contact),
                  onSelectToggle: (val) => onSelectToggle(contact.id, val),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
