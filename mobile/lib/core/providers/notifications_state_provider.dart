import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_cache_service.dart';
import '../services/notification_client_service.dart';

class NotificationsState {
  final List<InAppNotificationItem> notifications;
  final int unreadCount;
  final NotificationFilter activeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isOffline;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.activeFilter = NotificationFilter.all,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isOffline = false,
    this.errorMessage,
    this.hasMore = false,
    this.currentPage = 1,
  });

  NotificationsState copyWith({
    List<InAppNotificationItem>? notifications,
    int? unreadCount,
    NotificationFilter? activeFilter,
    bool? isLoading,
    bool? isRefreshing,
    bool? isOffline,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  /// Returns items matching the currently selected filter
  List<InAppNotificationItem> get filteredNotifications {
    if (activeFilter == NotificationFilter.unread) {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications;
  }

  /// Groups filtered notifications by 'Today', 'Yesterday', 'Earlier'
  Map<String, List<InAppNotificationItem>> get groupedNotifications {
    final list = filteredNotifications;
    final map = <String, List<InAppNotificationItem>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final item in list) {
      final key = item.dateGroupKey;
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(item);
    }

    // Remove empty groups to keep list clean
    map.removeWhere((key, value) => value.isEmpty);
    return map;
  }
}

final notificationsStateProvider =
    StateNotifierProvider<NotificationsStateNotifier, NotificationsState>((ref) {
  final service = ref.watch(notificationClientServiceProvider);
  return NotificationsStateNotifier(service);
});

class NotificationsStateNotifier extends StateNotifier<NotificationsState> {
  final NotificationClientService _service;
  bool _isFetching = false;

  NotificationsStateNotifier(this._service) : super(const NotificationsState()) {
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // 1. Immediate Cache Hydration
    final cached = await NotificationCacheService.getCachedNotifications();
    final cachedUnread = await NotificationCacheService.getCachedUnreadCount();

    if (cached.isNotEmpty) {
      state = state.copyWith(
        notifications: cached,
        unreadCount: cachedUnread,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Background Sync
    await loadNotifications(isRefresh: false);
  }

  /// Fetches latest notifications from server
  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    }

    try {
      final result = await _service.getNotifications(
        filter: NotificationFilter.all,
        page: 1,
        limit: 40,
      );

      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        hasMore: result.hasMore,
        currentPage: 1,
        isLoading: false,
        isRefreshing: false,
        isOffline: false,
        errorMessage: null,
      );

      // Persist to secure storage cache
      await NotificationCacheService.saveNotifications(result.notifications);
    } catch (e) {
      // Offline fallback: preserve existing notifications and display offline banner
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: true,
        errorMessage: state.notifications.isEmpty
            ? 'Connect to the internet to load your latest notifications.'
            : null,
      );
    } finally {
      _isFetching = false;
    }
  }

  /// Sets active filter (All vs Unread)
  void setFilter(NotificationFilter filter) {
    if (state.activeFilter == filter) return;
    state = state.copyWith(activeFilter: filter);
  }

  /// Marks a specific notification as read (optimistic UI update + background sync)
  Future<void> markAsRead(String id) async {
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final target = state.notifications[index];
    if (target.isRead) return; // already read

    final updated = List<InAppNotificationItem>.from(state.notifications);
    updated[index] = target.copyWith(isRead: true, readAt: DateTime.now());

    final newUnread = (state.unreadCount - 1).clamp(0, 9999);
    state = state.copyWith(
      notifications: updated,
      unreadCount: newUnread,
    );

    await NotificationCacheService.updateItemReadState(id, true);
    _service.markAsRead([id]);
  }

  /// Marks a specific notification as unread (optimistic UI update + background sync)
  Future<void> markAsUnread(String id) async {
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final target = state.notifications[index];
    if (!target.isRead) return; // already unread

    final updated = List<InAppNotificationItem>.from(state.notifications);
    updated[index] = target.copyWith(isRead: false, readAt: null);

    final newUnread = state.unreadCount + 1;
    state = state.copyWith(
      notifications: updated,
      unreadCount: newUnread,
    );

    await NotificationCacheService.updateItemReadState(id, false);
    _service.markAsUnread([id]);
  }

  /// Marks all notifications as read. Returns list of previously unread IDs for undo.
  Future<List<String>> markAllAsRead() async {
    final unreadIds = state.notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return [];

    final updated = state.notifications.map((n) {
      return n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now());
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: 0,
    );

    await NotificationCacheService.markAllAsReadInCache();
    _service.markAsRead(); // marks all read on backend

    return unreadIds;
  }

  /// Restores read state for specified IDs (Undo action)
  Future<void> undoMarkAllAsRead(List<String> restoredIds) async {
    if (restoredIds.isEmpty) return;

    final updated = state.notifications.map((n) {
      if (restoredIds.contains(n.id)) {
        return n.copyWith(isRead: false, readAt: null);
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: restoredIds.length,
    );

    await NotificationCacheService.saveNotifications(updated);
    _service.markAsUnread(restoredIds);
  }

  /// Ingests a new real-time or push notification into the state
  void onNotificationReceived(InAppNotificationItem notification) {
    // Prevent duplicate insertion
    if (state.notifications.any((n) => n.id == notification.id)) return;

    final updated = [notification, ...state.notifications];
    final unread = notification.isRead ? state.unreadCount : state.unreadCount + 1;

    state = state.copyWith(
      notifications: updated,
      unreadCount: unread,
    );

    NotificationCacheService.saveNotifications(updated);
  }
}
