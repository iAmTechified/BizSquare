import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/services/avatar_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/widgets/animated_critter_avatar.dart';
import '../../core/widgets/avatar_picker_sheet.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userState = ref.watch(userStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final biometricsEnabled = ref.watch(biometricsEnabledProvider);
    final activeAvatar = ref.watch(activeAvatarProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings & Preferences', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card with Animated Critter
          GestureDetector(
            onTap: () => AvatarPickerSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  AnimatedCritterAvatar(
                    avatar: activeAvatar.currentAvatar,
                    size: 48,
                    showGlow: false,
                    isInteractive: false,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState.businessName ?? 'Adebayo Stores',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          '${userState.username ?? "@adebayo_store"} · ${userState.primaryMicroNicheId ?? "Retail & Trade"}',
                          style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security & Biometrics
          _SectionHeader('SECURITY & BIOMETRICS'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E2E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, color: Color(0xFF4338CA), size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biometric Authentication', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Use Fingerprint / Face ID for fast login', style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Switch(
                  value: biometricsEnabled,
                  onChanged: (val) {
                    ref.read(biometricsEnabledProvider.notifier).state = val;
                  },
                  activeTrackColor: const Color(0xFF4338CA),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Home Screen Widget & Notifications
          _SectionHeader('HOME SCREEN & NOTIFICATIONS'),
          _MoreTile(
            icon: Icons.widgets_rounded,
            label: 'Home Screen Widget Setup',
            subtitle: 'Add 1-tap WhatsApp match widget to Home screen',
            isDark: isDark,
            onTap: () {
              ref.read(widgetServiceProvider).showAddWidgetPrompt(context);
            },
          ),
          _MoreTile(
            icon: Icons.notifications_active_rounded,
            label: 'Match & Alert Notifications',
            subtitle: 'Preview active business notifications',
            isDark: isDark,
            onTap: () {
              ref.read(notificationServiceProvider).showWelcomeNotificationBanner(context);
            },
          ),
          _MoreTile(
            icon: Icons.shield_outlined,
            label: 'Permissions Center',
            subtitle: 'Adjust contacts and system access',
            isDark: isDark,
            onTap: () => context.go('/permissions-wall'),
          ),
          const SizedBox(height: 12),

          _MoreTile(
            icon: Icons.hub_rounded,
            label: 'My Interests',
            subtitle: 'Manage baseline categories & demand graph',
            isDark: isDark,
            onTap: () => context.go('/my-interests'),
          ),
          const SizedBox(height: 20),

          // Theme Switcher Section
          _SectionHeader('APPEARANCE & THEME'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E2E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _ThemeOptionTile(
                  title: 'System Default',
                  subtitle: 'Match operating system theme',
                  mode: ThemeMode.system,
                  currentMode: themeMode,
                  onSelect: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system,
                ),
                const Divider(height: 1),
                _ThemeOptionTile(
                  title: 'Light Mode',
                  subtitle: 'High tints & off-whites',
                  mode: ThemeMode.light,
                  currentMode: themeMode,
                  onSelect: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                ),
                const Divider(height: 1),
                _ThemeOptionTile(
                  title: 'Dark Mode',
                  subtitle: 'Matte black & dark surface',
                  mode: ThemeMode.dark,
                  currentMode: themeMode,
                  onSelect: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          TextButton(
            onPressed: () {
              ref.read(userStateProvider.notifier).logout();
              context.go('/auth-wall');
            },
            child: Text(
              'Sign Out Account',
              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode currentMode;
  final VoidCallback onSelect;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.currentMode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4338CA), size: 20) : const SizedBox.shrink(),
      onTap: onSelect,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.8),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? onTap;

  const _MoreTile({required this.icon, required this.label, this.subtitle, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, size: 20, color: const Color(0xFF4338CA)),
        title: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))) : null,
        trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        onTap: onTap ?? () {},
      ),
    );
  }
}
