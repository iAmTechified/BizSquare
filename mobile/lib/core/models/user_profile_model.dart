class UserProfileModel {
  final String id;
  final String phoneNumber;
  final String? fullName;
  final String? businessName;
  final String? username;
  final int avatarId;
  final int akawoPoints;
  final bool isActive;
  final bool onboardingCompleted;
  final String verificationStatus;
  final DateTime createdAt;
  final List<UserSupplyNicheModel> supplyNiches;
  final List<UserBaselineInterestModel> baselineInterests;

  const UserProfileModel({
    required this.id,
    required this.phoneNumber,
    this.fullName,
    this.businessName,
    this.username,
    this.avatarId = 1,
    this.akawoPoints = 10,
    this.isActive = true,
    this.onboardingCompleted = false,
    this.verificationStatus = 'unverified',
    required this.createdAt,
    this.supplyNiches = const [],
    this.baselineInterests = const [],
  });

  String get displayName {
    if (businessName != null && businessName!.trim().isNotEmpty) {
      return businessName!.trim();
    }
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    return phoneNumber;
  }

  UserSupplyNicheModel? get primaryOffer {
    try {
      return supplyNiches.firstWhere((n) => n.isPrimary);
    } catch (_) {
      return supplyNiches.isNotEmpty ? supplyNiches.first : null;
    }
  }

  List<UserSupplyNicheModel> get secondaryOffers {
    return supplyNiches.where((n) => !n.isPrimary).toList();
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    var supplyList = <UserSupplyNicheModel>[];
    if (json['supplyNiches'] is List) {
      supplyList = (json['supplyNiches'] as List)
          .map((item) => UserSupplyNicheModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var interestList = <UserBaselineInterestModel>[];
    if (json['baselineInterests'] is List) {
      interestList = (json['baselineInterests'] as List)
          .map((item) => UserBaselineInterestModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    DateTime createdDate;
    try {
      createdDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      createdDate = DateTime.now();
    }

    return UserProfileModel(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      fullName: json['full_name'] as String?,
      businessName: json['business_name'] as String?,
      username: json['username'] as String?,
      avatarId: json['avatar_id'] as int? ?? 1,
      akawoPoints: json['akawo_points'] as int? ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String? ?? 'unverified',
      createdAt: createdDate,
      supplyNiches: supplyList,
      baselineInterests: interestList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'business_name': businessName,
      'username': username,
      'avatar_id': avatarId,
      'akawo_points': akawoPoints,
      'is_active': isActive,
      'onboarding_completed': onboardingCompleted,
      'verification_status': verificationStatus,
      'created_at': createdAt.toIso8601String(),
      'supplyNiches': supplyNiches.map((n) => n.toJson()).toList(),
      'baselineInterests': baselineInterests.map((i) => i.toJson()).toList(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? businessName,
    String? username,
    int? avatarId,
    int? akawoPoints,
    bool? isActive,
    bool? onboardingCompleted,
    String? verificationStatus,
    DateTime? createdAt,
    List<UserSupplyNicheModel>? supplyNiches,
    List<UserBaselineInterestModel>? baselineInterests,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      akawoPoints: akawoPoints ?? this.akawoPoints,
      isActive: isActive ?? this.isActive,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      supplyNiches: supplyNiches ?? this.supplyNiches,
      baselineInterests: baselineInterests ?? this.baselineInterests,
    );
  }
}

class UserSupplyNicheModel {
  final String microNicheId;
  final bool isPrimary;
  final String name;

  const UserSupplyNicheModel({
    required this.microNicheId,
    required this.isPrimary,
    required this.name,
  });

  factory UserSupplyNicheModel.fromJson(Map<String, dynamic> json) {
    return UserSupplyNicheModel(
      microNicheId: json['micro_niche_id'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'micro_niche_id': microNicheId,
      'is_primary': isPrimary,
      'name': name,
    };
  }
}

class UserBaselineInterestModel {
  final String taxonomyId;
  final String name;
  final String slug;

  const UserBaselineInterestModel({
    required this.taxonomyId,
    required this.name,
    required this.slug,
  });

  factory UserBaselineInterestModel.fromJson(Map<String, dynamic> json) {
    return UserBaselineInterestModel(
      taxonomyId: json['taxonomy_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxonomy_id': taxonomyId,
      'name': name,
      'slug': slug,
    };
  }
}

class UserSetupStatusModel {
  final bool profileCompleted;
  final bool primaryOfferSet;
  final bool interestsSet;
  final bool onboardingCompleted;

  const UserSetupStatusModel({
    this.profileCompleted = false,
    this.primaryOfferSet = false,
    this.interestsSet = false,
    this.onboardingCompleted = false,
  });

  int get remainingCount {
    int count = 0;
    if (!profileCompleted) count++;
    if (!primaryOfferSet) count++;
    if (!interestsSet) count++;
    return count;
  }

  bool get isAllCompleted => remainingCount == 0;

  factory UserSetupStatusModel.fromJson(Map<String, dynamic> json) {
    return UserSetupStatusModel(
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      primaryOfferSet: json['primaryOfferSet'] as bool? ?? false,
      interestsSet: json['interestsSet'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileCompleted': profileCompleted,
      'primaryOfferSet': primaryOfferSet,
      'interestsSet': interestsSet,
      'onboardingCompleted': onboardingCompleted,
    };
  }
}

class NotificationPreferencesModel {
  final bool spotlightUpdates;
  final bool contactGainUpdates;
  final bool accountAlerts;

  const NotificationPreferencesModel({
    this.spotlightUpdates = true,
    this.contactGainUpdates = true,
    this.accountAlerts = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      spotlightUpdates: json['spotlightUpdates'] as bool? ?? true,
      contactGainUpdates: json['contactGainUpdates'] as bool? ?? true,
      accountAlerts: json['accountAlerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spotlightUpdates': spotlightUpdates,
      'contactGainUpdates': contactGainUpdates,
      'accountAlerts': accountAlerts,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? spotlightUpdates,
    bool? contactGainUpdates,
    bool? accountAlerts,
  }) {
    return NotificationPreferencesModel(
      spotlightUpdates: spotlightUpdates ?? this.spotlightUpdates,
      contactGainUpdates: contactGainUpdates ?? this.contactGainUpdates,
      accountAlerts: accountAlerts ?? this.accountAlerts,
    );
  }
}

class PrivacyPreferencesModel {
  final bool discoverableInContactGain;
  final bool showBusinessOnSpotlight;

  const PrivacyPreferencesModel({
    this.discoverableInContactGain = true,
    this.showBusinessOnSpotlight = true,
  });

  factory PrivacyPreferencesModel.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferencesModel(
      discoverableInContactGain: json['discoverableInContactGain'] as bool? ?? true,
      showBusinessOnSpotlight: json['showBusinessOnSpotlight'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discoverableInContactGain': discoverableInContactGain,
      'showBusinessOnSpotlight': showBusinessOnSpotlight,
    };
  }

  PrivacyPreferencesModel copyWith({
    bool? discoverableInContactGain,
    bool? showBusinessOnSpotlight,
  }) {
    return PrivacyPreferencesModel(
      discoverableInContactGain: discoverableInContactGain ?? this.discoverableInContactGain,
      showBusinessOnSpotlight: showBusinessOnSpotlight ?? this.showBusinessOnSpotlight,
    );
  }
}
