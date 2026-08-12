import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum NotificationType {
  contactGain,
  contactSync,
  spotlight,
  account,
  permission,
  system;

  static NotificationType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'contact_gain':
      case 'new_contacts':
      case 'cycle_completed':
      case 'match':
        return NotificationType.contactGain;
      case 'contact_sync':
      case 'sync_failed':
      case 'sync_success':
        return NotificationType.contactSync;
      case 'spotlight':
      case 'spotlight_turn':
      case 'spotlight_verified':
      case 'spotlight_submission':
      case 'spotlight_cycle':
        return NotificationType.spotlight;
      case 'account':
      case 'security':
      case 'pin_changed':
      case 'profile_updated':
        return NotificationType.account;
      case 'permission':
      case 'permission_contacts':
      case 'permission_notifications':
        return NotificationType.permission;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  String toDbString() {
    switch (this) {
      case NotificationType.contactGain:
        return 'contact_gain';
      case NotificationType.contactSync:
        return 'contact_sync';
      case NotificationType.spotlight:
        return 'spotlight';
      case NotificationType.account:
        return 'account';
      case NotificationType.permission:
        return 'permission';
      case NotificationType.system:
        return 'system';
    }
  }
}

enum NotificationFilter {
  all,
  unread,
}

class InAppNotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  const InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.actionUrl,
    this.data = const {},
    required this.createdAt,
    this.readAt,
  });

  factory InAppNotificationItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'system';
    return InAppNotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NotificationType.fromString(typeStr),
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String? ?? json['action_url'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : (json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.toDbString(),
        'isRead': isRead,
        'actionUrl': actionUrl,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        if (readAt != null) 'readAt': readAt!.toIso8601String(),
      };

  InAppNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return InAppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Date group key for grouping list items
  String get dateGroupKey {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final differenceDays = today.difference(notificationDate).inDays;

    if (differenceDays == 0) return 'Today';
    if (differenceDays == 1) return 'Yesterday';
    return 'Earlier';
  }

  /// Relative human-readable smart timestamp
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// HugeIcon glyph based on type and read state
  dynamic get displayIcon {
    switch (type) {
      case NotificationType.contactGain:
        return HugeIcons.strokeRoundedUserAdd01;
      case NotificationType.contactSync:
        return HugeIcons.strokeRoundedRefresh;
      case NotificationType.spotlight:
        return HugeIcons.strokeRoundedSparkles;
      case NotificationType.account:
        return HugeIcons.strokeRoundedShieldUser;
      case NotificationType.permission:
        return HugeIcons.strokeRoundedAlertCircle;
      case NotificationType.system:
        return HugeIcons.strokeRoundedNotification01;
    }
  }

  /// Theme accent color for icon badge
  Color get iconColor {
    switch (type) {
      case NotificationType.contactGain:
        return const Color(0xFF0058FF);
      case NotificationType.spotlight:
        return const Color(0xFFF59E0B);
      case NotificationType.contactSync:
        return const Color(0xFF10B981);
      case NotificationType.account:
        return const Color(0xFF8B5CF6);
      case NotificationType.permission:
        return const Color(0xFFEF4444);
      case NotificationType.system:
        return const Color(0xFF0058FF);
    }
  }

  /// Deep link destination route
  String get resolvedDestinationRoute {
    if (actionUrl != null && actionUrl!.isNotEmpty) {
      return actionUrl!;
    }
    switch (type) {
      case NotificationType.contactGain:
        return '/contacts';
      case NotificationType.contactSync:
        return '/profile/contact-sync';
      case NotificationType.spotlight:
        return '/spotlight';
      case NotificationType.account:
        return '/profile/account';
      case NotificationType.permission:
        return '/profile/notifications';
      case NotificationType.system:
        return '/home';
    }
  }
}
