import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spotlight_model.dart';
import '../models/spotlight_widget_state.dart';
import '../services/widget_service.dart';
import 'home_state_provider.dart';

/// Provider that derives prepared SpotlightWidgetData snapshot from real application state.
final spotlightWidgetProvider = Provider<SpotlightWidgetData>((ref) {
  final homeState = ref.watch(homeStateProvider);
  final widgetService = ref.watch(widgetServiceProvider);

  final spotlight = homeState.spotlight;
  final now = DateTime.now();

  SpotlightWidgetStateType stateType;
  String headline;
  String subtitle;
  int participantCount = spotlight?.participantCount ?? 0;
  String actionLabel;
  String deepLink;
  String? cycleEndDate = spotlight?.cycleEndDate;

  if (spotlight?.isMyTurn == true) {
    final subStatus = spotlight?.submissionStatus;

    if (subStatus == SpotlightSubmissionStatus.notSubmitted ||
        subStatus == SpotlightSubmissionStatus.pending ||
        subStatus == SpotlightSubmissionStatus.needsChanges) {
      stateType = SpotlightWidgetStateType.submission;
      headline = "Your Spotlight needs attention";
      subtitle = "Complete your business offer post before turn ends";
      actionLabel = "Continue";
      deepLink = "/spotlight/edit-content";
    } else if (subStatus == SpotlightSubmissionStatus.verified) {
      stateType = SpotlightWidgetStateType.verified;
      headline = "Your Spotlight is live";
      subtitle = "$participantCount network member${participantCount == 1 ? '' : 's'} shared your offer";
      actionLabel = "View";
      deepLink = "/spotlight";
    } else {
      stateType = SpotlightWidgetStateType.yourTurn;
      headline = "It's your turn";
      subtitle = "Your business is featured in this cycle's network Spotlight";
      actionLabel = "Open Spotlight";
      deepLink = "/spotlight";
    }
  } else {
    stateType = SpotlightWidgetStateType.waiting;
    headline = "Next turn";
    subtitle = cycleEndDate != null && cycleEndDate.isNotEmpty
        ? "Community Spotlight cycle ends $cycleEndDate"
        : "Share for network partners to earn Akawo Points";
    actionLabel = "View";
    deepLink = "/spotlight";
  }

  final data = SpotlightWidgetData(
    stateType: stateType,
    title: 'SPOTLIGHT',
    headline: headline,
    subtitle: subtitle,
    participantCount: participantCount,
    actionLabel: actionLabel,
    deepLink: deepLink,
    cycleEndDate: cycleEndDate,
    timestamp: now,
  );

  // Sync to native OS widget storage
  widgetService.syncSpotlightNativeWidgetData(data);

  return data;
});
