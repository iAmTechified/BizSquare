/// Represents distinct production states for the Spotlight Widget
enum SpotlightWidgetStateType {
  yourTurn,   // State 1: It's the user's Spotlight turn
  submission, // State 2: User's submission needs completion/editing
  verified,   // State 3: User's Spotlight post is verified and live
  waiting,    // State 4: Next turn coming up in future cycle
}

/// Data snapshot for the Spotlight Widget
class SpotlightWidgetData {
  final SpotlightWidgetStateType stateType;
  final String title;
  final String headline;
  final String subtitle;
  final int participantCount;
  final String actionLabel;
  final String deepLink;
  final String? cycleEndDate;
  final DateTime timestamp;

  const SpotlightWidgetData({
    required this.stateType,
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.participantCount,
    required this.actionLabel,
    required this.deepLink,
    this.cycleEndDate,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'state_type': stateType.name,
      'title': title,
      'headline': headline,
      'subtitle': subtitle,
      'participant_count': participantCount,
      'action_label': actionLabel,
      'deep_link': deepLink,
      'cycle_end_date': cycleEndDate ?? '',
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SpotlightWidgetData.fromMap(Map<String, dynamic> map) {
    return SpotlightWidgetData(
      stateType: SpotlightWidgetStateType.values.firstWhere(
        (e) => e.name == map['state_type'],
        orElse: () => SpotlightWidgetStateType.waiting,
      ),
      title: map['title'] ?? 'SPOTLIGHT',
      headline: map['headline'] ?? 'Next turn',
      subtitle: map['subtitle'] ?? 'Community feature',
      participantCount: map['participant_count'] ?? 0,
      actionLabel: map['action_label'] ?? 'View',
      deepLink: map['deep_link'] ?? '/spotlight',
      cycleEndDate: map['cycle_end_date'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
