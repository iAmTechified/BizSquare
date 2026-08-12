class ContactGainRecentItem {
  final String contactId;
  final String userId;
  final String businessName;
  final String? fullName;
  final String? phoneNumber;
  final int avatarId;
  final String primaryOffer;
  final DateTime gainedDate;
  final String matchReason;
  final String tier;
  final bool isMutual;
  final double score;

  const ContactGainRecentItem({
    required this.contactId,
    required this.userId,
    required this.businessName,
    this.fullName,
    this.phoneNumber,
    required this.avatarId,
    required this.primaryOffer,
    required this.gainedDate,
    required this.matchReason,
    required this.tier,
    required this.isMutual,
    required this.score,
  });

  factory ContactGainRecentItem.fromJson(Map<String, dynamic> json) {
    return ContactGainRecentItem(
      contactId: json['contactId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      businessName: json['businessName'] as String? ?? 'Verified Business',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatarId: json['avatarId'] as int? ?? 1,
      primaryOffer: json['primaryOffer'] as String? ?? 'Business',
      gainedDate: json['gainedDate'] != null
          ? DateTime.tryParse(json['gainedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      matchReason: json['matchReason'] as String? ?? 'WEEKLY_CONTACT_GAIN',
      tier: json['tier'] as String? ?? 'TIER_1',
      isMutual: json['isMutual'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'contactId': contactId,
        'userId': userId,
        'businessName': businessName,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'avatarId': avatarId,
        'primaryOffer': primaryOffer,
        'gainedDate': gainedDate.toIso8601String(),
        'matchReason': matchReason,
        'tier': tier,
        'isMutual': isMutual,
        'score': score,
      };
}

class ContactGainSummaryModel {
  final int weeklyTarget;
  final int gainedThisWeek;
  final int remainingCount;
  final String status; // 'NO_CONTACTS', 'IN_PROGRESS', 'TARGET_REACHED', 'UNDERFILLED', 'SYNC_PENDING'
  final String syncStatus; // 'SYNCED', 'PENDING_SYNC'
  final String? underfillReason;
  final String batchDate;
  final List<ContactGainRecentItem> recentContacts;

  const ContactGainSummaryModel({
    required this.weeklyTarget,
    required this.gainedThisWeek,
    required this.remainingCount,
    required this.status,
    required this.syncStatus,
    this.underfillReason,
    required this.batchDate,
    required this.recentContacts,
  });

  factory ContactGainSummaryModel.fromJson(Map<String, dynamic> json) {
    final list = json['recentContacts'] as List<dynamic>? ?? [];
    return ContactGainSummaryModel(
      weeklyTarget: json['weeklyTarget'] as int? ?? 0,
      gainedThisWeek: json['gainedThisWeek'] as int? ?? 0,
      remainingCount: json['remainingCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'NO_CONTACTS',
      syncStatus: json['syncStatus'] as String? ?? 'SYNCED',
      underfillReason: json['underfillReason'] as String?,
      batchDate: json['batchDate'] as String? ?? '',
      recentContacts: list.map((e) => ContactGainRecentItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'weeklyTarget': weeklyTarget,
        'gainedThisWeek': gainedThisWeek,
        'remainingCount': remainingCount,
        'status': status,
        'syncStatus': syncStatus,
        'underfillReason': underfillReason,
        'batchDate': batchDate,
        'recentContacts': recentContacts.map((e) => e.toJson()).toList(),
      };
}
