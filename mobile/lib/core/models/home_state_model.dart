import 'contact_gain_summary_model.dart';
import 'spotlight_model.dart';
import 'notification_model.dart';

class HomeState {
  final String? userName;
  final String? businessName;
  final int avatarId;
  final bool isNewUser;
  final bool isOffline;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  // Setup Progress (1 to 5)
  final int completedSetupSteps;
  final int totalSetupSteps;
  final bool profileCompleted;
  final bool primaryOfferSet;
  final bool interestsSet;
  final bool contactsPermissionGranted;
  final bool notificationsPermissionGranted;

  // Contact Gain
  final ContactGainSummaryModel? contactGain;

  // Spotlight
  final SpotlightCurrentModel? spotlight;

  // Notifications
  final List<InAppNotificationItem> notifications;
  final int unreadNotificationCount;

  const HomeState({
    this.userName,
    this.businessName,
    this.avatarId = 1,
    this.isNewUser = false,
    this.isOffline = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.completedSetupSteps = 0,
    this.totalSetupSteps = 5,
    this.profileCompleted = false,
    this.primaryOfferSet = false,
    this.interestsSet = false,
    this.contactsPermissionGranted = false,
    this.notificationsPermissionGranted = false,
    this.contactGain,
    this.spotlight,
    this.notifications = const [],
    this.unreadNotificationCount = 0,
  });

  bool get isFullySetup => completedSetupSteps >= totalSetupSteps;

  HomeState copyWith({
    String? userName,
    String? businessName,
    int? avatarId,
    bool? isNewUser,
    bool? isOffline,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    int? completedSetupSteps,
    int? totalSetupSteps,
    bool? profileCompleted,
    bool? primaryOfferSet,
    bool? interestsSet,
    bool? contactsPermissionGranted,
    bool? notificationsPermissionGranted,
    ContactGainSummaryModel? contactGain,
    SpotlightCurrentModel? spotlight,
    List<InAppNotificationItem>? notifications,
    int? unreadNotificationCount,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      businessName: businessName ?? this.businessName,
      avatarId: avatarId ?? this.avatarId,
      isNewUser: isNewUser ?? this.isNewUser,
      isOffline: isOffline ?? this.isOffline,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      completedSetupSteps: completedSetupSteps ?? this.completedSetupSteps,
      totalSetupSteps: totalSetupSteps ?? this.totalSetupSteps,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      primaryOfferSet: primaryOfferSet ?? this.primaryOfferSet,
      interestsSet: interestsSet ?? this.interestsSet,
      contactsPermissionGranted: contactsPermissionGranted ?? this.contactsPermissionGranted,
      notificationsPermissionGranted: notificationsPermissionGranted ?? this.notificationsPermissionGranted,
      contactGain: contactGain ?? this.contactGain,
      spotlight: spotlight ?? this.spotlight,
      notifications: notifications ?? this.notifications,
      unreadNotificationCount: unreadNotificationCount ?? this.unreadNotificationCount,
    );
  }
}
