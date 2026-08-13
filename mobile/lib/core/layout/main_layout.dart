import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../widgets/dynamic_app_launch_prompt_sheet.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _checkedLaunchPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerLaunchPromptCheck();
    });
  }

  Future<void> _triggerLaunchPromptCheck() async {
    if (_checkedLaunchPrompt) return;
    _checkedLaunchPrompt = true;

    // Small initial delay so home screen mounts cleanly first
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await DynamicAppLaunchPromptSheet.checkAndPromptIfNeeded(context, ref);
    }
  }

  static const List<_TabConfig> _tabs = [
    _TabConfig(
      label: 'Home',
      icon: HugeIcons.strokeRoundedHome01,
    ),
    _TabConfig(
      label: 'Contacts',
      icon: HugeIcons.strokeRoundedContact01,
    ),
    _TabConfig(
      label: 'Spotlight',
      icon: HugeIcons.strokeRoundedFlash,
    ),
    _TabConfig(
      label: 'Profile',
      icon: HugeIcons.strokeRoundedUser,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFFAFAFA);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          widget.navigationShell,
          // Bottom Fade Overlay under the floating tabs
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 110,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor.withValues(alpha: 0.0),
                      bgColor.withValues(alpha: 0.75),
                      bgColor.withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / _tabs.length;
                  return Stack(
                    children: [
                      // Solid Blue Active Indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * tabWidth + 4,
                        top: 4,
                        width: tabWidth - 8,
                        height: constraints.maxHeight - 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0058FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                                widget.navigationShell.goBranch(
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
                                        icon: tab.icon,
                                        color: isActive
                                            ? Colors.white
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
                                              ? Colors.white
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
                  );
                },
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

  const _TabConfig({
    required this.label,
    required this.icon,
  });
}
