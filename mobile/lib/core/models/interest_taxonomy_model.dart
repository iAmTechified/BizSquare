class InterestTaxonomyModel {
  final String id;
  final String slug;
  final String name;
  final String? parentId;
  final String? description;
  final String contextType;
  final String icon;
  final int sortOrder;
  final bool isActive;
  final List<String> aliases;
  final int contentCount;
  final int activeContentCount;
  final List<InterestTaxonomyModel> children;

  InterestTaxonomyModel({
    required this.id,
    required this.slug,
    required this.name,
    this.parentId,
    this.description,
    required this.contextType,
    required this.icon,
    required this.sortOrder,
    required this.isActive,
    required this.aliases,
    required this.contentCount,
    required this.activeContentCount,
    this.children = const [],
  });

  factory InterestTaxonomyModel.fromJson(Map<String, dynamic> json) {
    return InterestTaxonomyModel(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      parentId: json['parent_id'],
      description: json['description'],
      contextType: json['context_type'] ?? 'general',
      icon: json['icon'] ?? 'category',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      contentCount: json['content_count'] ?? 0,
      activeContentCount: json['active_content_count'] ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => InterestTaxonomyModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
