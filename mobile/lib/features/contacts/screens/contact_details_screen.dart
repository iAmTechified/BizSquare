import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/unified_contact_model.dart';
import '../../../../core/widgets/animated_critter_avatar.dart';
import '../../../../core/services/avatar_service.dart';
import '../../../../core/utils/phone_normalizer.dart';

class ContactDetailsScreen extends StatelessWidget {
  final UnifiedContactModel contact;

  const ContactDetailsScreen({super.key, required this.contact});

  Future<void> _makeCall() async {
    final uri = Uri.parse('tel:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendSms() async {
    final uri = Uri.parse('sms:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp() async {
    final url = PhoneNormalizer.getWhatsAppUrl(
      contact.phoneNumber,
      defaultMessage: 'Hello ${contact.displayName}, I connected with you on BizSquare!',
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Details',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar & Name Card
            Center(
              child: AnimatedCritterAvatar(
                avatar: AvatarService.getAvatarByIndex(contact.avatarId),
                size: 84,
                showGlow: contact.isSquareContact,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            if (contact.businessName != null && contact.businessName != contact.displayName) ...[
              const SizedBox(height: 4),
              Text(
                contact.businessName!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 12),
            if (contact.isSquareContact)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BIZSQUARE SQUARE CONTACT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0058FF),
                    letterSpacing: 0.6,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Communication Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (contact.hasPhoneCall)
                  _buildCircleAction(
                    icon: HugeIcons.strokeRoundedCall,
                    label: 'Call',
                    color: const Color(0xFF0058FF),
                    onTap: _makeCall,
                  ),
                if (contact.hasSms) ...[
                  const SizedBox(width: 16),
                  _buildCircleAction(
                    icon: HugeIcons.strokeRoundedMessage01,
                    label: 'SMS',
                    color: const Color(0xFF475569),
                    onTap: _sendSms,
                  ),
                ],
                if (contact.hasWhatsApp) ...[
                  const SizedBox(width: 16),
                  _buildCircleAction(
                    icon: HugeIcons.strokeRoundedChat01,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: _openWhatsApp,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // Metadata Section Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow('Phone Number', PhoneNormalizer.formatDisplay(contact.phoneNumber), isDark),
                  const Divider(height: 24),
                  _buildMetaRow('Primary Offer', contact.primaryOffer ?? 'Verified Business', isDark),
                  if (contact.gainedDate != null) ...[
                    const Divider(height: 24),
                    _buildMetaRow('Gained Date', contact.gainedDate!.toLocal().toString().split('.')[0], isDark),
                  ],
                  if (contact.matchReason != null) ...[
                    const Divider(height: 24),
                    _buildMetaRow('Match Category', contact.matchReason!, isDark),
                  ],
                  const Divider(height: 24),
                  _buildMetaRow('Sync Status', contact.syncState.name.toUpperCase(), isDark),
                ],
              ),
            ),

            // Notes Section
            if (contact.notes != null && contact.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Private Notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contact.notes!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(icon: icon, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
