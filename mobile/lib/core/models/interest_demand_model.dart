class CurrentDemandItemModel {
  final String taxonomyId;
  final String slug;
  final String name;
  final String contextType;
  final String state;
  final double strength;
  final double confidence;
  final double recencyScore;
  final int frequencyCount;
  final String? lastPositiveAt;
  final bool isBaseline;

  CurrentDemandItemModel({
    required this.taxonomyId,
    required this.slug,
    required this.name,
    required this.contextType,
    required this.state,
    required this.strength,
    required this.confidence,
    required this.recencyScore,
    required this.frequencyCount,
    this.lastPositiveAt,
    required this.isBaseline,
  });

  factory CurrentDemandItemModel.fromJson(Map<String, dynamic> json) {
    return CurrentDemandItemModel(
      taxonomyId: json['taxonomy_id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      contextType: json['context_type'] ?? 'general',
      state: json['state'] ?? 'EMERGING',
      strength: (json['strength'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recencyScore: (json['recency_score'] as num?)?.toDouble() ?? 1.0,
      frequencyCount: json['frequency_count'] ?? 1,
      lastPositiveAt: json['last_positive_at'],
      isBaseline: json['is_baseline'] ?? false,
    );
  }
}

class UserCurrentDemandModel {
  final String userId;
  final String calculatedAt;
  final List<CurrentDemandItemModel> demandTierHigh;
  final List<CurrentDemandItemModel> demandTierMedium;
  final List<CurrentDemandItemModel> demandTierEmerging;
  final List<CurrentDemandItemModel> backgroundInterests;
  final List<CurrentDemandItemModel> dormantInterests;

  UserCurrentDemandModel({
    required this.userId,
    required this.calculatedAt,
    required this.demandTierHigh,
    required this.demandTierMedium,
    required this.demandTierEmerging,
    required this.backgroundInterests,
    required this.dormantInterests,
  });

  factory UserCurrentDemandModel.fromJson(Map<String, dynamic> json) {
    return UserCurrentDemandModel(
      userId: json['user_id'] ?? '',
      calculatedAt: json['calculated_at'] ?? '',
      demandTierHigh: (json['demand_tier_high'] as List<dynamic>?)
              ?.map((e) => CurrentDemandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      demandTierMedium: (json['demand_tier_medium'] as List<dynamic>?)
              ?.map((e) => CurrentDemandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      demandTierEmerging: (json['demand_tier_emerging'] as List<dynamic>?)
              ?.map((e) => CurrentDemandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      backgroundInterests: (json['background_interests'] as List<dynamic>?)
              ?.map((e) => CurrentDemandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dormantInterests: (json['dormant_interests'] as List<dynamic>?)
              ?.map((e) => CurrentDemandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
