import 'dart:convert';

class OnboardingDraft {
  final int currentStep;
  final String? businessName;
  final String? phoneNumber;
  final int selectedAvatarId;
  final List<String> selectedMicroNicheIds;
  final String? primaryMicroNicheId;
  final String? verificationCode;
  final bool isVerified;
  final String? pin;
  final String? username;
  final List<String> selectedInterestIds;
  final DateTime lastUpdated;

  const OnboardingDraft({
    this.currentStep = 1,
    this.businessName,
    this.phoneNumber,
    this.selectedAvatarId = 1,
    this.selectedMicroNicheIds = const [],
    this.primaryMicroNicheId,
    this.verificationCode,
    this.isVerified = false,
    this.pin,
    this.username,
    this.selectedInterestIds = const [],
    required this.lastUpdated,
  });

  factory OnboardingDraft.initial() {
    return OnboardingDraft(
      currentStep: 1,
      selectedAvatarId: 1,
      selectedMicroNicheIds: const [],
      selectedInterestIds: const [],
      lastUpdated: DateTime.now(),
    );
  }

  OnboardingDraft copyWith({
    int? currentStep,
    String? businessName,
    String? phoneNumber,
    int? selectedAvatarId,
    List<String>? selectedMicroNicheIds,
    String? primaryMicroNicheId,
    String? verificationCode,
    bool? isVerified,
    String? pin,
    String? username,
    List<String>? selectedInterestIds,
    DateTime? lastUpdated,
  }) {
    return OnboardingDraft(
      currentStep: currentStep ?? this.currentStep,
      businessName: businessName ?? this.businessName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
      selectedMicroNicheIds: selectedMicroNicheIds ?? this.selectedMicroNicheIds,
      primaryMicroNicheId: primaryMicroNicheId ?? this.primaryMicroNicheId,
      verificationCode: verificationCode ?? this.verificationCode,
      isVerified: isVerified ?? this.isVerified,
      pin: pin ?? this.pin,
      username: username ?? this.username,
      selectedInterestIds: selectedInterestIds ?? this.selectedInterestIds,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStep': currentStep,
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'selectedAvatarId': selectedAvatarId,
      'selectedMicroNicheIds': selectedMicroNicheIds,
      'primaryMicroNicheId': primaryMicroNicheId,
      'verificationCode': verificationCode,
      'isVerified': isVerified,
      'pin': pin,
      'username': username,
      'selectedInterestIds': selectedInterestIds,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory OnboardingDraft.fromMap(Map<String, dynamic> map) {
    return OnboardingDraft(
      currentStep: map['currentStep'] as int? ?? 1,
      businessName: map['businessName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      selectedAvatarId: map['selectedAvatarId'] as int? ?? 1,
      selectedMicroNicheIds: (map['selectedMicroNicheIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      primaryMicroNicheId: map['primaryMicroNicheId'] as String?,
      verificationCode: map['verificationCode'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      pin: map['pin'] as String?,
      username: map['username'] as String?,
      selectedInterestIds: (map['selectedInterestIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      lastUpdated: map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory OnboardingDraft.fromJson(String source) => OnboardingDraft.fromMap(json.decode(source) as Map<String, dynamic>);
}
