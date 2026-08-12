class InAppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;

  const InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.actionUrl,
    required this.createdAt,
  });

  factory InAppNotificationItem.fromJson(Map<String, dynamic> json) {
    return InAppNotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'actionUrl': actionUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
