import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/notifications_state_provider.dart';
import 'widgets/notification_item_tile.dart';
import 'widgets/notification_skeleton_list.dart';
import 'widgets/notifications_empty_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger background refresh when opening Notifications screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsStateProvider.notifier).loadNotifications(isRefresh: false);
    });
  }

  void _handleMarkAllAsRead() async {
    HapticFeedback.mediumImpact();
    final previousUnreadIds =
        await ref.read(notificationsStateProvider.notifier).markAllAsRead();

    if (!mounted) return;

    if (previousUnreadIds.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All notifications marked as read',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFF60A5FA),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref
                  .read(notificationsStateProvider.notifier)
                  .undoMarkAllAsRead(previousUnreadIds);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unreadCount = state.unreadCount;
    final totalCount = state.notifications.length;
    final grouped = state.groupedNotifications;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreHorizontal,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              size: 22,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 8,
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _handleMarkAllAsRead();
              } else if (value == 'settings') {
                HapticFeedback.selectionClick();
                context.push('/profile/notifications');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                enabled: unreadCount > 0,
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: Color(0xFF0058FF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mark all as read',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: unreadCount > 0
                            ? (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A))
                            : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSettings01,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Notification settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Offline Banner Indicator
            if (state.isOffline && state.notifications.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? const Color(0xFF3B1E08) : const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedWifi01,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You're offline. Showing your saved notifications.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Filter Pills: [All] [Unread]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // 'All' Filter Pill
                  _buildFilterPill(
                    label: 'All',
                    count: totalCount,
                    isSelected: state.activeFilter == NotificationFilter.all,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(notificationsStateProvider.notifier)
                          .setFilter(NotificationFilter.all);
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),

                  // 'Unread' Filter Pill
                  _buildFilterPill(
                    label: 'Unread',
                    count: unreadCount,
                    isSelected: state.activeFilter == NotificationFilter.unread,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(notificationsStateProvider.notifier)
                          .setFilter(NotificationFilter.unread);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // 3. Body List / Skeleton / Empty State
            Expanded(
              child: state.isLoading
                  ? const NotificationSkeletonList()
                  : state.filteredNotifications.isEmpty
                      ? NotificationsEmptyState(
                          filter: state.activeFilter,
                          isOffline: state.isOffline,
                          onRetry: () => ref
                              .read(notificationsStateProvider.notifier)
                              .loadNotifications(isRefresh: true),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(notificationsStateProvider.notifier)
                              .loadNotifications(isRefresh: true),
                          color: const Color(0xFF0058FF),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ).copyWith(bottom: 32),
                            itemCount: grouped.length,
                            itemBuilder: (context, groupIndex) {
                              final groupKey = grouped.keys.elementAt(groupIndex);
                              final items = grouped[groupKey]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Group Header
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: groupIndex == 0 ? 4 : 16,
                                      bottom: 10,
                                    ),
                                    child: Text(
                                      groupKey,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),

                                  // List of notification items in this date group
                                  ...items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: NotificationItemTile(item: item),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0058FF)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
