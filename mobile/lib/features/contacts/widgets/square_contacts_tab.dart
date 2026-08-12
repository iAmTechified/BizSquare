import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/unified_contact_model.dart';
import 'contact_card.dart';

class SquareContactsTab extends StatelessWidget {
  final List<UnifiedContactModel> contacts;
  final String? expandedContactId;
  final bool isSelectionMode;
  final Set<String> selectedContactIds;
  final Future<void> Function() onRefresh;
  final void Function(String) onCardToggle;
  final void Function(UnifiedContactModel) onStarToggle;
  final void Function(UnifiedContactModel) onArchive;
  final void Function(String, bool?) onSelectToggle;
  final void Function(String) onLongPress;

  const SquareContactsTab({
    super.key,
    required this.contacts,
    this.expandedContactId,
    this.isSelectionMode = false,
    this.selectedContactIds = const {},
    required this.onRefresh,
    required this.onCardToggle,
    required this.onStarToggle,
    required this.onArchive,
    required this.onSelectToggle,
    required this.onLongPress,
  });

  Map<String, List<UnifiedContactModel>> _groupTimeline(List<UnifiedContactModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final groups = <String, List<UnifiedContactModel>>{};

    for (final c in list) {
      final date = c.gainedDate ?? now;
      final cDay = DateTime(date.year, date.month, date.day);

      if (cDay.isAtSameMomentAs(today) || cDay.isAfter(today)) {
        groups.putIfAbsent('TODAY', () => []).add(c);
      } else if (cDay.isAtSameMomentAs(yesterday)) {
        groups.putIfAbsent('YESTERDAY', () => []).add(c);
      } else if (cDay.isAfter(thisWeekStart)) {
        groups.putIfAbsent('THIS WEEK', () => []).add(c);
      } else if (cDay.isAfter(lastWeekStart)) {
        groups.putIfAbsent('LAST WEEK', () => []).add(c);
      } else {
        groups.putIfAbsent('OLDER', () => []).add(c);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (contacts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFF0058FF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          children: [
            Center(
              child: Container(
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
            ),
            const SizedBox(height: 24),
            Text(
              'No Square Contacts yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your new contacts will appear here automatically when Contact Gain matches you with relevant business partners.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupTimeline(contacts);
    final groupKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF0058FF),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: groupKeys.length + 1, // 1 for Top Weekly Info Card
        itemBuilder: (context, index) {
          if (index == 0) {
            // Top Weekly Info Card
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0058FF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'THIS WEEK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${contacts.length} Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${contacts.length} new contacts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your contacts are being added automatically through Contact Gain.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            );
          }

          final groupTitle = groupKeys[index - 1];
          final groupContacts = grouped[groupTitle]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  groupTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ...groupContacts.map((contact) {
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
