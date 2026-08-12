import '../utils/phone_normalizer.dart';

enum ContactSyncState {
  synced,
  pending,
  failed,
  permissionRequired,
}

class ContactLabelModel {
  final String id;
  final String name;
  final String color;
  final int count;

  const ContactLabelModel({
    required this.id,
    required this.name,
    this.color = '#0058FF',
    this.count = 0,
  });

  factory ContactLabelModel.fromJson(Map<String, dynamic> json) {
    return ContactLabelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#0058FF',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'count': count,
  };
}

class UnifiedContactModel {
  final String id;
  final String? deviceContactId;
  final String? squareContactId;
  final String? userId;
  final String fullName;
  final String? businessName;
  final String phoneNumber;
  final String canonicalPhone;
  final int avatarId;
  final String? primaryOffer;
  final List<String> secondaryOffers;
  final bool isSquareContact;
  final bool isStarred;
  final bool isArchived;
  final List<String> labels;
  final String? notes;
  final DateTime? gainedDate;
  final String? matchReason;
  final bool isMutual;
  final ContactSyncState syncState;

  const UnifiedContactModel({
    required this.id,
    this.deviceContactId,
    this.squareContactId,
    this.userId,
    required this.fullName,
    this.businessName,
    required this.phoneNumber,
    required this.canonicalPhone,
    this.avatarId = 1,
    this.primaryOffer,
    this.secondaryOffers = const [],
    this.isSquareContact = false,
    this.isStarred = false,
    this.isArchived = false,
    this.labels = const [],
    this.notes,
    this.gainedDate,
    this.matchReason,
    this.isMutual = false,
    this.syncState = ContactSyncState.synced,
  });

  bool get hasWhatsApp => PhoneNormalizer.isValidWhatsAppCandidate(phoneNumber);
  bool get hasPhoneCall => phoneNumber.isNotEmpty;
  bool get hasSms => phoneNumber.isNotEmpty;

  String get displayName {
    if (fullName.isNotEmpty && fullName != 'Partner') return fullName;
    if (businessName != null && businessName!.isNotEmpty) return businessName!;
    return phoneNumber;
  }

  String get displaySubtitle {
    if (businessName != null && businessName!.isNotEmpty && businessName != fullName) {
      return businessName!;
    }
    if (primaryOffer != null && primaryOffer!.isNotEmpty) {
      return primaryOffer!;
    }
    return phoneNumber;
  }

  UnifiedContactModel copyWith({
    String? id,
    String? deviceContactId,
    String? squareContactId,
    String? userId,
    String? fullName,
    String? businessName,
    String? phoneNumber,
    String? canonicalPhone,
    int? avatarId,
    String? primaryOffer,
    List<String>? secondaryOffers,
    bool? isSquareContact,
    bool? isStarred,
    bool? isArchived,
    List<String>? labels,
    String? notes,
    DateTime? gainedDate,
    String? matchReason,
    bool? isMutual,
    ContactSyncState? syncState,
  }) {
    return UnifiedContactModel(
      id: id ?? this.id,
      deviceContactId: deviceContactId ?? this.deviceContactId,
      squareContactId: squareContactId ?? this.squareContactId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      canonicalPhone: canonicalPhone ?? this.canonicalPhone,
      avatarId: avatarId ?? this.avatarId,
      primaryOffer: primaryOffer ?? this.primaryOffer,
      secondaryOffers: secondaryOffers ?? this.secondaryOffers,
      isSquareContact: isSquareContact ?? this.isSquareContact,
      isStarred: isStarred ?? this.isStarred,
      isArchived: isArchived ?? this.isArchived,
      labels: labels ?? this.labels,
      notes: notes ?? this.notes,
      gainedDate: gainedDate ?? this.gainedDate,
      matchReason: matchReason ?? this.matchReason,
      isMutual: isMutual ?? this.isMutual,
      syncState: syncState ?? this.syncState,
    );
  }

  factory UnifiedContactModel.fromJson(Map<String, dynamic> json) {
    final rawPhone = json['phoneNumber'] as String? ?? json['phone_number'] as String? ?? '';
    final canonical = PhoneNormalizer.normalize(rawPhone);
    final rawSync = json['syncStatus'] as String? ?? json['sync_status'] as String? ?? 'SYNCED';

    ContactSyncState syncState;
    switch (rawSync.toUpperCase()) {
      case 'PENDING':
        syncState = ContactSyncState.pending;
        break;
      case 'FAILED':
        syncState = ContactSyncState.failed;
        break;
      case 'PERMISSION_REQUIRED':
        syncState = ContactSyncState.permissionRequired;
        break;
      case 'SYNCED':
      default:
        syncState = ContactSyncState.synced;
        break;
    }

    final rawDate = json['gainedDate'] as String? ?? json['gained_date'] as String?;
    DateTime? gainedDate;
    if (rawDate != null) {
      try {
        gainedDate = DateTime.parse(rawDate).toLocal();
      } catch (_) {}
    }

    return UnifiedContactModel(
      id: json['id'] as String? ?? canonical,
      deviceContactId: json['deviceContactId'] as String?,
      squareContactId: json['squareContactId'] as String? ?? json['id'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String?,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      businessName: json['businessName'] as String? ?? json['business_name'] as String?,
      phoneNumber: rawPhone,
      canonicalPhone: canonical,
      avatarId: (json['avatarId'] as num?)?.toInt() ?? (json['avatar_id'] as num?)?.toInt() ?? 1,
      primaryOffer: json['primaryOffer'] as String? ?? json['primary_offer'] as String?,
      secondaryOffers: (json['secondaryOffers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isSquareContact: json['isSquareContact'] as bool? ?? json['is_square_contact'] as bool? ?? true,
      isStarred: json['isStarred'] as bool? ?? json['is_starred'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? json['is_archived'] as bool? ?? false,
      labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'] as String?,
      gainedDate: gainedDate,
      matchReason: json['matchReason'] as String? ?? json['match_reason'] as String?,
      isMutual: json['isMutual'] as bool? ?? json['is_mutual'] as bool? ?? false,
      syncState: syncState,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceContactId': deviceContactId,
    'squareContactId': squareContactId,
    'userId': userId,
    'fullName': fullName,
    'businessName': businessName,
    'phoneNumber': phoneNumber,
    'canonicalPhone': canonicalPhone,
    'avatarId': avatarId,
    'primaryOffer': primaryOffer,
    'secondaryOffers': secondaryOffers,
    'isSquareContact': isSquareContact,
    'isStarred': isStarred,
    'isArchived': isArchived,
    'labels': labels,
    'notes': notes,
    'gainedDate': gainedDate?.toIso8601String(),
    'matchReason': matchReason,
    'isMutual': isMutual,
    'syncStatus': syncState.name.toUpperCase(),
  };
}

class DuplicateContactPair {
  final UnifiedContactModel primary;
  final UnifiedContactModel duplicate;
  final String reason;

  const DuplicateContactPair({
    required this.primary,
    required this.duplicate,
    required this.reason,
  });
}
