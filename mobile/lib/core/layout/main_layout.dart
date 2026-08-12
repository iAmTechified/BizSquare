import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  static const List<_TabConfig> _tabs = [
    _TabConfig(
      label: 'Home',
      icon: HugeIcons.strokeRoundedHome01,
      activeIcon: HugeIcons.strokeRoundedHome01,
    ),
    _TabConfig(
      label: 'Contacts',
      icon: HugeIcons.strokeRoundedContact01,
      activeIcon: HugeIcons.strokeRoundedContact01,
    ),
    _TabConfig(
      label: 'Spotlight',
      icon: HugeIcons.strokeRoundedFlash,
      activeIcon: HugeIcons.strokeRoundedFlash,
    ),
    _TabConfig(
      label: 'Profile',
      icon: HugeIcons.strokeRoundedUser,
      activeIcon: HugeIcons.strokeRoundedUser,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          height: 64,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131C31).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Stack(
                children: [
                  // Sliding Glass Indicator
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tabWidth = constraints.maxWidth / _tabs.length;
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * tabWidth + 4,
                        top: 4,
                        width: tabWidth - 8,
                        height: constraints.maxHeight - 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.16 : 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0058FF).withValues(alpha: isDark ? 0.35 : 0.25),
                              width: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Tab Items
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      final isActive = index == currentIndex;

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            navigationShell.goBranch(
                              index,
                              initialLocation: index == currentIndex,
                            );
                          },
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Center(
                            child: AnimatedScale(
                              scale: isActive ? 1.04 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HugeIcon(
                                    icon: isActive ? tab.activeIcon : tab.icon,
                                    color: isActive
                                        ? const Color(0xFF0058FF)
                                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                    size: 22,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tab.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                      color: isActive
                                          ? const Color(0xFF0058FF)
                                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final dynamic icon;
  final dynamic activeIcon;

  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
