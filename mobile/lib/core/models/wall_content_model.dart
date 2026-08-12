class ContentOptionModel {
  final String optionKey;
  final String label;
  final String? subtext;
  final String? mediaUrl;

  ContentOptionModel({
    required this.optionKey,
    required this.label,
    this.subtext,
    this.mediaUrl,
  });

  factory ContentOptionModel.fromJson(Map<String, dynamic> json) {
    return ContentOptionModel(
      optionKey: json['option_key'] ?? '',
      label: json['label'] ?? '',
      subtext: json['subtext'],
      mediaUrl: json['media_url'],
    );
  }
}

class WallSessionItemModel {
  final String contentId;
  final String format;
  final String titlePrompt;
  final String? description;
  final String? mediaUrl;
  final String mediaType;
  final String contextType;
  final String poolType;
  final int orderIndex;
  final List<ContentOptionModel> options;

  WallSessionItemModel({
    required this.contentId,
    required this.format,
    required this.titlePrompt,
    this.description,
    this.mediaUrl,
    this.mediaType = 'none',
    this.contextType = 'general',
    this.poolType = 'PERSONALIZED',
    required this.orderIndex,
    required this.options,
  });

  factory WallSessionItemModel.fromJson(Map<String, dynamic> json) {
    return WallSessionItemModel(
      contentId: json['content_id'] ?? '',
      format: json['format'] ?? 'THIS_OR_THAT',
      titlePrompt: json['title_prompt'] ?? '',
      description: json['description'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] ?? 'none',
      contextType: json['context_type'] ?? 'general',
      poolType: json['pool_type'] ?? 'PERSONALIZED',
      orderIndex: json['order_index'] ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => ContentOptionModel.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WallSessionModel {
  final String sessionId;
  final String date;
  final int itemCount;
  final List<WallSessionItemModel> items;

  WallSessionModel({
    required this.sessionId,
    required this.date,
    required this.itemCount,
    required this.items,
  });

  factory WallSessionModel.fromJson(Map<String, dynamic> json) {
    return WallSessionModel(
      sessionId: json['session_id'] ?? '',
      date: json['date']?.toString() ?? '',
      itemCount: json['item_count'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => WallSessionItemModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
