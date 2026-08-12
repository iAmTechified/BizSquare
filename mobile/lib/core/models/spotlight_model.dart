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

class SpotlightCurrentModel {
  final String? campaignId;
  final bool isMyTurn;
  final SpotlightUserModel? user;
  final SpotlightContentModel? content;
  final int targetParticipants;
  final int participantCount;
  final bool hasParticipated;
  final String startDate;
  final String endDate;

  const SpotlightCurrentModel({
    this.campaignId,
    required this.isMyTurn,
    this.user,
    this.content,
    required this.targetParticipants,
    required this.participantCount,
    required this.hasParticipated,
    required this.startDate,
    required this.endDate,
  });

  factory SpotlightCurrentModel.fromJson(Map<String, dynamic> json) {
    return SpotlightCurrentModel(
      campaignId: json['campaignId'] as String?,
      isMyTurn: json['isMyTurn'] as bool? ?? false,
      user: json['user'] != null ? SpotlightUserModel.fromJson(json['user'] as Map<String, dynamic>) : null,
      content: json['content'] != null ? SpotlightContentModel.fromJson(json['content'] as Map<String, dynamic>) : null,
      targetParticipants: json['targetParticipants'] as int? ?? 48,
      participantCount: json['participantCount'] as int? ?? 0,
      hasParticipated: json['hasParticipated'] as bool? ?? false,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
    );
  }

  SpotlightCurrentModel copyWith({
    String? campaignId,
    bool? isMyTurn,
    SpotlightUserModel? user,
    SpotlightContentModel? content,
    int? targetParticipants,
    int? participantCount,
    bool? hasParticipated,
    String? startDate,
    String? endDate,
  }) {
    return SpotlightCurrentModel(
      campaignId: campaignId ?? this.campaignId,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      user: user ?? this.user,
      content: content ?? this.content,
      targetParticipants: targetParticipants ?? this.targetParticipants,
      participantCount: participantCount ?? this.participantCount,
      hasParticipated: hasParticipated ?? this.hasParticipated,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'isMyTurn': isMyTurn,
        'user': user?.toJson(),
        'content': content?.toJson(),
        'targetParticipants': targetParticipants,
        'participantCount': participantCount,
        'hasParticipated': hasParticipated,
        'startDate': startDate,
        'endDate': endDate,
      };
}

class SpotlightHistoryItem {
  final String campaignId;
  final String title;
  final String promoText;
  final String caption;
  final String? flyerUrl;
  final String? creatorBusinessName;
  final String? creatorName;
  final String? creatorPrimaryOffer;
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
    this.creatorPrimaryOffer,
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
      participantCount: json['participantCount'] as int? ?? 0,
      targetParticipants: json['targetParticipants'] as int? ?? 48,
      date: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  factory SpotlightHistoryItem.fromJsonOthers(Map<String, dynamic> json) {
    return SpotlightHistoryItem(
      campaignId: json['participationId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      promoText: json['promoText'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      flyerUrl: json['flyerUrl'] as String?,
      creatorBusinessName: json['creatorBusinessName'] as String?,
      creatorName: json['creatorName'] as String?,
      creatorPrimaryOffer: json['creatorPrimaryOffer'] as String?,
      participantCount: 1,
      targetParticipants: 48,
      date: json['participatedAt'] != null ? DateTime.tryParse(json['participatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
