import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/unified_contact_model.dart';
import '../../../../core/widgets/animated_critter_avatar.dart';
import '../../../../core/services/avatar_service.dart';
import '../../../../core/utils/phone_normalizer.dart';

class ContactCard extends StatelessWidget {
  final UnifiedContactModel contact;
  final bool isExpanded;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onStarToggle;
  final VoidCallback onArchive;
  final ValueChanged<bool?> onSelectToggle;

  const ContactCard({
    super.key,
    required this.contact,
    this.isExpanded = false,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    required this.onLongPress,
    required this.onStarToggle,
    required this.onArchive,
    required this.onSelectToggle,
  });

  String _formatSmartDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Received today';
    if (diff.inDays == 1) return 'Received yesterday';
    if (diff.inDays < 7) return 'Received ${diff.inDays}d ago';
    if (diff.inDays < 30) return 'Received ${(diff.inDays / 7).floor()}w ago';
    return 'Received ${(diff.inDays / 30).floor()}m ago';
  }

  Future<void> _makeCall() async {
    final uri = Uri.parse('tel:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms() async {
    final uri = Uri.parse('sms:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final url = PhoneNormalizer.getWhatsAppUrl(
      contact.phoneNumber,
      defaultMessage: 'Hello ${contact.displayName}, I connected with you on BizSquare!',
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey('contact_${contact.id}'),
      direction: isSelectionMode ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Star
          onStarToggle();
          return false;
        } else {
          // Swipe Left: Archive
          onArchive();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${contact.displayName} archived'),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: const Color(0xFF5AFF00),
                onPressed: () {},
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          return true;
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedStar,
          color: Colors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0055),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedArchive,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0058FF)
                : (isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isSelectionMode ? () => onSelectToggle(!isSelected) : onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapsed Row
                  Row(
                    children: [
                      if (isSelectionMode) ...[
                        Checkbox(
                          value: isSelected,
                          activeColor: const Color(0xFF0058FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: onSelectToggle,
                        ),
                        const SizedBox(width: 4),
                      ],

                      // Avatar
                      AnimatedCritterAvatar(
                        avatar: AvatarService.getAvatarByIndex(contact.avatarId),
                        size: 44,
                        showGlow: false,
                      ),
                      const SizedBox(width: 12),

                      // Name, Offer & Square Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    contact.displayName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (contact.isSquareContact) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SQUARE',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0058FF),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.displaySubtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: contact.isSquareContact
                                    ? const Color(0xFF0058FF)
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Star Toggle Button
                      IconButton(
                        icon: HugeIcon(
                          icon: contact.isStarred ? HugeIcons.strokeRoundedStar : HugeIcons.strokeRoundedStar,
                          color: contact.isStarred ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: onStarToggle,
                      ),
                    ],
                  ),

                  // Expanded Section
                  if (isExpanded) ...[
                    const Divider(height: 20),

                    // Phone & Gained Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          PhoneNormalizer.formatDisplay(contact.phoneNumber),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                        if (contact.gainedDate != null)
                          Text(
                            _formatSmartDate(contact.gainedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0058FF),
                            ),
                          ),
                      ],
                    ),

                    // Labels Pills
                    if (contact.labels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: contact.labels.map((lbl) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              lbl,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Communication Action Buttons
                    Row(
                      children: [
                        if (contact.hasPhoneCall)
                          _buildActionBtn(
                            icon: HugeIcons.strokeRoundedCall,
                            label: 'Call',
                            color: const Color(0xFF0058FF),
                            onTap: _makeCall,
                            isDark: isDark,
                          ),
                        if (contact.hasSms) ...[
                          const SizedBox(width: 8),
                          _buildActionBtn(
                            icon: HugeIcons.strokeRoundedMessage01,
                            label: 'SMS',
                            color: const Color(0xFF475569),
                            onTap: _sendSms,
                            isDark: isDark,
                          ),
                        ],
                        if (contact.hasWhatsApp) ...[
                          const SizedBox(width: 8),
                          _buildActionBtn(
                            icon: HugeIcons.strokeRoundedChat01,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: _openWhatsApp,
                            isDark: isDark,
                          ),
                        ],
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            context.push('/contacts/details', extra: contact);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Text(
                                  'Details',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0058FF),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  color: Color(0xFF0058FF),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
