import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_gain_widget_state.dart';
import '../services/widget_service.dart';
import 'home_state_provider.dart';
import 'permission_state_provider.dart';

/// Provider that calculates the dynamic Contact Gain Widget state
/// from real application state and syncs with native OS home screen widgets.
final contactGainWidgetProvider = Provider<ContactGainWidgetData>((ref) {
  final homeState = ref.watch(homeStateProvider);
  final permState = ref.watch(permissionStateProvider);
  final widgetService = ref.watch(widgetServiceProvider);

  final summary = homeState.contactGain;

  ContactGainWidgetStateType stateType;
  String headline;
  String subtitle;
  int contactCount = 0;
  String actionLabel;
  String deepLink;
  String? nextUpdateDate;
  String? errorMessage = homeState.errorMessage;

  // 1. OFFLINE CHECK (State G)
  if (homeState.isOffline) {
    stateType = ContactGainWidgetStateType.offline;
    headline = "You're offline";
    subtitle = "Showing your latest network update";
    contactCount = summary?.gainedThisWeek ?? 0;
    actionLabel = "View";
    deepLink = "/contacts";
  }
  // 2. SETUP REQUIRED CHECK (State A)
  else if (!permState.isContactsGranted || !homeState.contactsPermissionGranted) {
    stateType = ContactGainWidgetStateType.setupRequired;
    headline = "Contact Gain needs setup";
    subtitle = "Turn on contact sync to receive your weekly network batch";
    contactCount = 0;
    actionLabel = "Fix";
    deepLink = "/permissions-wall";
  }
  // 3. ERROR STATE CHECK (State F)
  else if (summary?.syncStatus == 'ERROR' || (errorMessage != null && errorMessage.contains('failed'))) {
    stateType = ContactGainWidgetStateType.error;
    headline = "Contact sync needs attention";
    subtitle = errorMessage ?? "Sync failure detected. Tap to resolve.";
    contactCount = 0;
    actionLabel = "Fix";
    deepLink = "/profile/contact-sync";
  }
  // 4. PROCESSING STATE CHECK (State C)
  else if (homeState.isRefreshing || summary?.status == 'PROCESSING') {
    stateType = ContactGainWidgetStateType.processing;
    headline = "Building your network";
    subtitle = "Analyzing mutual interest signals across BizSquare";
    contactCount = 0;
    actionLabel = "Building...";
    deepLink = "/home";
  }
  // 5. READY STATE CHECK (State D)
  else if (summary != null && (summary.remainingCount > 0 || summary.status == 'READY')) {
    stateType = ContactGainWidgetStateType.ready;
    contactCount = summary.remainingCount > 0 ? summary.remainingCount : summary.gainedThisWeek;
    headline = "Your network is ready";
    subtitle = "+$contactCount new Square Contacts waiting for you";
    actionLabel = "View";
    deepLink = "/contacts";
  }
  // 6. COMPLETED STATE CHECK (State E)
  else if (summary != null && summary.gainedThisWeek > 0 && summary.status == 'SYNCED') {
    stateType = ContactGainWidgetStateType.completed;
    contactCount = summary.gainedThisWeek;
    headline = "This week's network";
    subtitle = "$contactCount new contacts added to your Square";
    actionLabel = "View contacts";
    deepLink = "/contacts";
  }
  // 7. WAITING STATE CHECK (State B)
  else {
    stateType = ContactGainWidgetStateType.waiting;
    headline = "Next network update";

    // Calculate real next Sunday cycle date
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    final nextSunday = now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    nextUpdateDate = _formatShortDate(nextSunday);

    subtitle = "Weekly matching cycle runs $nextUpdateDate";
    contactCount = 0;
    actionLabel = "Status";
    deepLink = "/home";
  }

  final data = ContactGainWidgetData(
    stateType: stateType,
    title: 'BIZSQUARE',
    headline: headline,
    subtitle: subtitle,
    contactCount: contactCount,
    actionLabel: actionLabel,
    deepLink: deepLink,
    isOffline: homeState.isOffline,
    nextUpdateDate: nextUpdateDate,
    errorMessage: errorMessage,
    timestamp: DateTime.now(),
  );

  // Sync state data to native OS home screen widget storage asynchronously
  widgetService.syncNativeWidgetData(data);

  return data;
});

String _formatShortDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}
