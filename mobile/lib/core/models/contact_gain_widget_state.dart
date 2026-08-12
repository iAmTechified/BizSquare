/// Represents the 7 distinct production states for the Contact Gain Widget
enum ContactGainWidgetStateType {
  setupRequired, // State A: Permission or profile setup needed
  waiting,       // State B: Cycle waiting for next network update
  processing,    // State C: System actively building the weekly network
  ready,         // State D: New contacts ready to view (+N contacts)
  completed,     // State E: Latest contacts already viewed (N new contacts)
  error,         // State F: Contact sync / network error
  offline,       // State G: Offline state showing cached data
}

/// Data snapshot for the Contact Gain Widget (used by UI components and Native OS widgets)
class ContactGainWidgetData {
  final ContactGainWidgetStateType stateType;
  final String title;
  final String headline;
  final String subtitle;
  final int contactCount;
  final String actionLabel;
  final String deepLink;
  final bool isOffline;
  final String? nextUpdateDate;
  final String? errorMessage;
  final DateTime timestamp;

  const ContactGainWidgetData({
    required this.stateType,
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.contactCount,
    required this.actionLabel,
    required this.deepLink,
    this.isOffline = false,
    this.nextUpdateDate,
    this.errorMessage,
    required this.timestamp,
  });

  /// Serializes data to JSON-compatible map for Native OS Home Screen Widgets (via home_widget)
  Map<String, dynamic> toMap() {
    return {
      'state_type': stateType.name,
      'title': title,
      'headline': headline,
      'subtitle': subtitle,
      'contact_count': contactCount,
      'action_label': actionLabel,
      'deep_link': deepLink,
      'is_offline': isOffline,
      'next_update_date': nextUpdateDate ?? '',
      'error_message': errorMessage ?? '',
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserializes map from Native OS storage
  factory ContactGainWidgetData.fromMap(Map<String, dynamic> map) {
    return ContactGainWidgetData(
      stateType: ContactGainWidgetStateType.values.firstWhere(
        (e) => e.name == map['state_type'],
        orElse: () => ContactGainWidgetStateType.waiting,
      ),
      title: map['title'] ?? 'BIZSQUARE',
      headline: map['headline'] ?? 'Next network update',
      subtitle: map['subtitle'] ?? 'Sunday cycle',
      contactCount: map['contact_count'] ?? 0,
      actionLabel: map['action_label'] ?? 'View',
      deepLink: map['deep_link'] ?? '/home',
      isOffline: map['is_offline'] ?? false,
      nextUpdateDate: map['next_update_date'],
      errorMessage: map['error_message'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
