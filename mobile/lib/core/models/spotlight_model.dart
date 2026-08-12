class SpotlightRequirementModel {
  final String prompt;
  final int maxCharacters;
  final String placeholder;

  const SpotlightRequirementModel({
    required this.prompt,
    required this.maxCharacters,
    required this.placeholder,
  });

  factory SpotlightRequirementModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SpotlightRequirementModel(
        prompt: 'What are you sharing this cycle? Showcase your best product, offer, or service to the network.',
        maxCharacters: 300,
        placeholder: "e.g. 20% discount on all Men's Native Wears this week with nationwide delivery...",
      );
    }
    return SpotlightRequirementModel(
      prompt: json['prompt'] as String? ?? 'What are you sharing this cycle?',
      maxCharacters: json['maxCharacters'] as int? ?? 300,
      placeholder: json['placeholder'] as String? ?? 'Enter details about your offer...',
    );
  }

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'maxCharacters': maxCharacters,
        'placeholder': placeholder,
      };
}

class SpotlightUserModel {
  final String id;
  final String businessName;
  final String fullName;
  final String? phoneNumber;
  final int avatarId;
  final String primaryOffer;

  const SpotlightUserModel({
    required this.id,
    required this.businessName,
    required this.fullName,
    this.phoneNumber,
    required this.avatarId,
    required this.primaryOffer,
  });

  factory SpotlightUserModel.fromJson(Map<String, dynamic> json) {
    return SpotlightUserModel(
      id: json['id'] as String? ?? '',
      businessName: json['businessName'] as String? ?? 'BizSquare Owner',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarId: json['avatarId'] as int? ?? 1,
      primaryOffer: json['primaryOffer'] as String? ?? 'Verified Business',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'avatarId': avatarId,
        'primaryOffer': primaryOffer,
      };
}

class SpotlightContentModel {
  final String title;
  final String promoText;
  final String caption;
  final String? flyerUrl;

  const SpotlightContentModel({
    required this.title,
    required this.promoText,
    required this.caption,
    this.flyerUrl,
  });

  factory SpotlightContentModel.fromJson(Map<String, dynamic> json) {
    return SpotlightContentModel(
      title: json['title'] as String? ?? 'Spotlight Feature',
      promoText: json['promoText'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      flyerUrl: json['flyerUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'promoText': promoText,
        'caption': caption,
        'flyerUrl': flyerUrl,
      };
}

enum SpotlightTurnStatus {
  myTurn,
  notMyTurn,
  waiting,
}

enum SpotlightSubmissionStatus {
  notSubmitted,
  pending,
  verified,
  needsChanges,
}

class SpotlightCurrentModel {
  final String? campaignId;
  final bool isMyTurn;
  final SpotlightTurnStatus turnStatus;
  final int cycleNumber;
  final String cycleStartDate;
  final String cycleEndDate;
  final SpotlightSubmissionStatus submissionStatus;
  final String? rejectionReason;
  final SpotlightRequirementModel requirement;
  final SpotlightUserModel? user;
  final SpotlightContentModel? content;
  final int targetParticipants;
  final int participantCount;
  final bool hasParticipated;

  const SpotlightCurrentModel({
    this.campaignId,
    required this.isMyTurn,
    this.turnStatus = SpotlightTurnStatus.notMyTurn,
    this.cycleNumber = 1,
    required this.cycleStartDate,
    required this.cycleEndDate,
    this.submissionStatus = SpotlightSubmissionStatus.verified,
    this.rejectionReason,
    this.requirement = const SpotlightRequirementModel(
      prompt: 'What are you sharing this cycle? Showcase your best product, offer, or service to the network.',
      maxCharacters: 300,
      placeholder: 'Enter details about your offer...',
    ),
    this.user,
    this.content,
    required this.targetParticipants,
    required this.participantCount,
    required this.hasParticipated,
  });

  factory SpotlightCurrentModel.fromJson(Map<String, dynamic> json) {
    final isMyTurn = json['isMyTurn'] as bool? ?? false;
    final turnStatusStr = json['turnStatus'] as String? ?? (isMyTurn ? 'my_turn' : 'not_my_turn');
    final submissionStatusStr = json['submissionStatus'] as String? ?? 'verified';

    SpotlightTurnStatus turnStatus = SpotlightTurnStatus.notMyTurn;
    if (turnStatusStr == 'my_turn' || isMyTurn) {
      turnStatus = SpotlightTurnStatus.myTurn;
    } else if (turnStatusStr == 'waiting') {
      turnStatus = SpotlightTurnStatus.waiting;
    }

    SpotlightSubmissionStatus subStatus = SpotlightSubmissionStatus.verified;
    if (submissionStatusStr == 'pending') {
      subStatus = SpotlightSubmissionStatus.pending;
    } else if (submissionStatusStr == 'needs_changes' || submissionStatusStr == 'rejected') {
      subStatus = SpotlightSubmissionStatus.needsChanges;
    } else if (submissionStatusStr == 'not_submitted') {
      subStatus = SpotlightSubmissionStatus.notSubmitted;
    }

    return SpotlightCurrentModel(
      campaignId: json['campaignId'] as String?,
      isMyTurn: isMyTurn,
      turnStatus: turnStatus,
      cycleNumber: json['cycleNumber'] as int? ?? 1,
      cycleStartDate: json['cycleStartDate'] as String? ?? json['startDate'] as String? ?? '',
      cycleEndDate: json['cycleEndDate'] as String? ?? json['endDate'] as String? ?? '',
      submissionStatus: subStatus,
      rejectionReason: json['rejectionReason'] as String?,
      requirement: SpotlightRequirementModel.fromJson(json['submissionRequirement'] as Map<String, dynamic>?),
      user: json['user'] != null ? SpotlightUserModel.fromJson(json['user'] as Map<String, dynamic>) : null,
      content: json['content'] != null ? SpotlightContentModel.fromJson(json['content'] as Map<String, dynamic>) : null,
      targetParticipants: json['targetParticipants'] as int? ?? 48,
      participantCount: json['participantCount'] as int? ?? 0,
      hasParticipated: json['hasParticipated'] as bool? ?? false,
    );
  }

  SpotlightCurrentModel copyWith({
    String? campaignId,
    bool? isMyTurn,
    SpotlightTurnStatus? turnStatus,
    int? cycleNumber,
    String? cycleStartDate,
    String? cycleEndDate,
    SpotlightSubmissionStatus? submissionStatus,
    String? rejectionReason,
    SpotlightRequirementModel? requirement,
    SpotlightUserModel? user,
    SpotlightContentModel? content,
    int? targetParticipants,
    int? participantCount,
    bool? hasParticipated,
  }) {
    return SpotlightCurrentModel(
      campaignId: campaignId ?? this.campaignId,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      turnStatus: turnStatus ?? this.turnStatus,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      cycleEndDate: cycleEndDate ?? this.cycleEndDate,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requirement: requirement ?? this.requirement,
      user: user ?? this.user,
      content: content ?? this.content,
      targetParticipants: targetParticipants ?? this.targetParticipants,
      participantCount: participantCount ?? this.participantCount,
      hasParticipated: hasParticipated ?? this.hasParticipated,
    );
  }

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'isMyTurn': isMyTurn,
        'turnStatus': turnStatus.name,
        'cycleNumber': cycleNumber,
        'cycleStartDate': cycleStartDate,
        'cycleEndDate': cycleEndDate,
        'submissionStatus': submissionStatus.name,
        'rejectionReason': rejectionReason,
        'submissionRequirement': requirement.toJson(),
        'user': user?.toJson(),
        'content': content?.toJson(),
        'targetParticipants': targetParticipants,
        'participantCount': participantCount,
        'hasParticipated': hasParticipated,
      };
}

class SpotlightParticipantModel {
  final String id;
  final String businessName;
  final String fullName;
  final int avatarId;
  final String primaryOffer;
  final DateTime participatedAt;

  const SpotlightParticipantModel({
    required this.id,
    required this.businessName,
    required this.fullName,
    required this.avatarId,
    required this.primaryOffer,
    required this.participatedAt,
  });

  factory SpotlightParticipantModel.fromJson(Map<String, dynamic> json) {
    return SpotlightParticipantModel(
      id: json['id'] as String? ?? '',
      businessName: json['businessName'] as String? ?? 'Verified Member',
      fullName: json['fullName'] as String? ?? '',
      avatarId: json['avatarId'] as int? ?? 1,
      primaryOffer: json['primaryOffer'] as String? ?? 'Business Owner',
      participatedAt: json['participatedAt'] != null
          ? DateTime.tryParse(json['participatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SpotlightHistoryItem {
  final String campaignId;
  final String title;
  final String promoText;
  final String caption;
  final String? flyerUrl;
  final String? creatorBusinessName;
  final String? creatorName;
  final int? creatorAvatar;
  final String? creatorPrimaryOffer;
  final String submissionStatus;
  final String? rejectionReason;
  final int participantCount;
  final int targetParticipants;
  final DateTime date;

  const SpotlightHistoryItem({
    required this.campaignId,
    required this.title,
    required this.promoText,
    required this.caption,
    this.flyerUrl,
    this.creatorBusinessName,
    this.creatorName,
    this.creatorAvatar,
    this.creatorPrimaryOffer,
    this.submissionStatus = 'verified',
    this.rejectionReason,
    required this.participantCount,
    required this.targetParticipants,
    required this.date,
  });

  factory SpotlightHistoryItem.fromJsonMine(Map<String, dynamic> json) {
    return SpotlightHistoryItem(
      campaignId: json['campaignId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      promoText: json['promoText'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      flyerUrl: json['flyerUrl'] as String?,
      submissionStatus: json['submissionStatus'] as String? ?? 'verified',
      rejectionReason: json['rejectionReason'] as String?,
      participantCount: json['participantCount'] as int? ?? 0,
      targetParticipants: json['targetParticipants'] as int? ?? 48,
      date: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory SpotlightHistoryItem.fromJsonOthers(Map<String, dynamic> json) {
    return SpotlightHistoryItem(
      campaignId: json['campaignId'] as String? ?? json['participationId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      promoText: json['promoText'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      flyerUrl: json['flyerUrl'] as String?,
      creatorBusinessName: json['creatorBusinessName'] as String?,
      creatorName: json['creatorName'] as String?,
      creatorAvatar: json['creatorAvatar'] as int?,
      creatorPrimaryOffer: json['creatorPrimaryOffer'] as String?,
      submissionStatus: 'verified',
      participantCount: json['participantCount'] as int? ?? 1,
      targetParticipants: 48,
      date: json['participatedAt'] != null
          ? DateTime.tryParse(json['participatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SpotlightSubmissionDraft {
  final String title;
  final String promoText;
  final String caption;
  final String? flyerUrl;
  final DateTime lastSaved;

  const SpotlightSubmissionDraft({
    required this.title,
    required this.promoText,
    required this.caption,
    this.flyerUrl,
    required this.lastSaved,
  });

  factory SpotlightSubmissionDraft.fromJson(Map<String, dynamic> json) {
    return SpotlightSubmissionDraft(
      title: json['title'] as String? ?? '',
      promoText: json['promoText'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      flyerUrl: json['flyerUrl'] as String?,
      lastSaved: json['lastSaved'] != null
          ? DateTime.tryParse(json['lastSaved'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'promoText': promoText,
        'caption': caption,
        'flyerUrl': flyerUrl,
        'lastSaved': lastSaved.toIso8601String(),
      };
}
