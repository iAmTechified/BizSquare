import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/notification_service.dart';

class PermissionsWallScreen extends ConsumerStatefulWidget {
  const PermissionsWallScreen({super.key});

  @override
  ConsumerState<PermissionsWallScreen> createState() => _PermissionsWallScreenState();
}

class _PermissionsWallScreenState extends ConsumerState<PermissionsWallScreen> {
  bool _contactsGranted = false;
  bool _notificationsGranted = false;
  bool _biometricsGranted = true;

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() => _notificationsGranted = status.isGranted);
      if (status.isGranted) {
        ref.read(notificationServiceProvider).showWelcomeNotificationBanner(context);
      }
    }
  }

  Future<void> _requestContacts() async {
    final status = await Permission.contacts.request();
    if (mounted) {
      setState(() => _contactsGranted = status.isGranted);
    }
  }

  void _proceed() {
    context.go('/daily-wall');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SETUP TIPS & PERMISSIONS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4338CA),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Unlock full\nautomation.',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable key permissions and biometrics to auto-sync matched business contacts and secure your account.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),

              // Notifications Permission Tile
              _PermissionTile(
                icon: Icons.notifications_active_rounded,
                title: 'Match Alerts & Updates',
                desc: 'Receive immediate notifications when verified businesses accept your cards.',
                isGranted: _notificationsGranted,
                accent: const Color(0xFF004DE0),
                onToggle: _requestNotification,
              ),
              const SizedBox(height: 14),

              // Biometrics Permission Tile
              _PermissionTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Security',
                desc: 'Instant and secure sign-in with Fingerprint / Face ID.',
                isGranted: _biometricsGranted,
                accent: const Color(0xFF4338CA),
                onToggle: () {
                  setState(() => _biometricsGranted = !_biometricsGranted);
                  ref.read(biometricsEnabledProvider.notifier).state = _biometricsGranted;
                },
              ),
              const SizedBox(height: 14),

              // Contacts Permission Tile
              _PermissionTile(
                icon: Icons.contacts_rounded,
                title: 'Address Book Integration',
                desc: 'Auto-saves verified supply & demand contacts seamlessly.',
                isGranted: _contactsGranted,
                accent: const Color(0xFF10B981),
                onToggle: _requestContacts,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue to Daily Wall →',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Permissions can be adjusted anytime in settings.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final bool isGranted;
  final Color accent;
  final VoidCallback onToggle;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.isGranted,
    required this.accent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGranted ? accent : (isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isGranted,
            onChanged: (_) => onToggle(),
            activeTrackColor: accent,
          ),
        ],
      ),
    );
  }
}
