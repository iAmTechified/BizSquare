class MicroNiche {
  final String id;
  final String categoryId;
  final String name;
  final bool isActive;

  const MicroNiche({
    required this.id,
    required this.categoryId,
    required this.name,
    this.isActive = true,
  });

  factory MicroNiche.fromJson(Map<String, dynamic> json) {
    return MicroNiche(
      id: json['id'] as String,
      categoryId: json['category_id'] as String? ?? json['categoryId'] as String? ?? '',
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'is_active': isActive,
  };
}

class Category {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;
  final List<MicroNiche> microNiches;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
    this.microNiches = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawNiches = json['microNiches'] as List<dynamic>? ?? json['micro_niches'] as List<dynamic>? ?? [];
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'store',
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      microNiches: rawNiches.map((e) => MicroNiche.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'sort_order': sortOrder,
    'micro_niches': microNiches.map((n) => n.toJson()).toList(),
  };
}

/// Offline-first seed taxonomy matching backend database schema v2
class MicroNicheTaxonomy {
  static const List<Category> categories = [
    Category(
      id: 'cat_01_fashion',
      name: 'Fashion & Apparel',
      icon: 'shopping_bag',
      sortOrder: 1,
      microNiches: [
        MicroNiche(id: 'mn_footwear', categoryId: 'cat_01_fashion', name: 'Footwear'),
        MicroNiche(id: 'mn_jewelry_watches', categoryId: 'cat_01_fashion', name: 'Jewelry & Watches'),
        MicroNiche(id: 'mn_mens_clothing', categoryId: 'cat_01_fashion', name: "Men's Clothing"),
        MicroNiche(id: 'mn_womens_clothing', categoryId: 'cat_01_fashion', name: "Women's Clothing"),
        MicroNiche(id: 'mn_bags_accessories', categoryId: 'cat_01_fashion', name: 'Bags & Accessories'),
        MicroNiche(id: 'mn_childrens_clothing', categoryId: 'cat_01_fashion', name: "Children's Clothing"),
        MicroNiche(id: 'mn_fabrics_textiles', categoryId: 'cat_01_fashion', name: 'Fabrics & Textiles'),
      ],
    ),
    Category(
      id: 'cat_02_food',
      name: 'Food & Beverage',
      icon: 'restaurant',
      sortOrder: 2,
      microNiches: [
        MicroNiche(id: 'mn_packaged_foods', categoryId: 'cat_02_food', name: 'Packaged Foods & Snacks'),
        MicroNiche(id: 'mn_beverages_drinks', categoryId: 'cat_02_food', name: 'Beverages & Drinks'),
        MicroNiche(id: 'mn_catering_events', categoryId: 'cat_02_food', name: 'Catering & Event Food'),
        MicroNiche(id: 'mn_bakery_confectionery', categoryId: 'cat_02_food', name: 'Bakery & Confectionery'),
        MicroNiche(id: 'mn_fresh_produce', categoryId: 'cat_02_food', name: 'Fresh Produce & Groceries'),
        MicroNiche(id: 'mn_restaurant_fastfood', categoryId: 'cat_02_food', name: 'Restaurant & Fast Food'),
      ],
    ),
    Category(
      id: 'cat_03_tech',
      name: 'Tech & Gadgets',
      icon: 'devices',
      sortOrder: 3,
      microNiches: [
        MicroNiche(id: 'mn_smartphones_laptops', categoryId: 'cat_03_tech', name: 'Smartphones & Laptops'),
        MicroNiche(id: 'mn_tech_accessories', categoryId: 'cat_03_tech', name: 'Tech Accessories'),
        MicroNiche(id: 'mn_device_repairs', categoryId: 'cat_03_tech', name: 'Device Repairs'),
        MicroNiche(id: 'mn_software_saas', categoryId: 'cat_03_tech', name: 'Software & SaaS'),
        MicroNiche(id: 'mn_consumer_electronics', categoryId: 'cat_03_tech', name: 'Consumer Electronics'),
        MicroNiche(id: 'mn_networking_security', categoryId: 'cat_03_tech', name: 'Networking & Security'),
      ],
    ),
    Category(
      id: 'cat_04_beauty',
      name: 'Beauty & Personal Care',
      icon: 'spa',
      sortOrder: 4,
      microNiches: [
        MicroNiche(id: 'mn_skincare', categoryId: 'cat_04_beauty', name: 'Skincare Products'),
        MicroNiche(id: 'mn_haircare_wigs', categoryId: 'cat_04_beauty', name: 'Hair Care & Wigs'),
        MicroNiche(id: 'mn_makeup_cosmetics', categoryId: 'cat_04_beauty', name: 'Makeup & Cosmetics'),
        MicroNiche(id: 'mn_perfumes_fragrances', categoryId: 'cat_04_beauty', name: 'Perfumes & Fragrances'),
        MicroNiche(id: 'mn_salon_spa', categoryId: 'cat_04_beauty', name: 'Salon & Spa Services'),
      ],
    ),
    Category(
      id: 'cat_05_health',
      name: 'Health & Wellness',
      icon: 'health_and_safety',
      sortOrder: 5,
      microNiches: [
        MicroNiche(id: 'mn_pharmacy_medicine', categoryId: 'cat_05_health', name: 'Pharmacy & Medicine'),
        MicroNiche(id: 'mn_fitness_gym', categoryId: 'cat_05_health', name: 'Fitness & Gym'),
        MicroNiche(id: 'mn_herbal_remedies', categoryId: 'cat_05_health', name: 'Herbal & Natural Remedies'),
        MicroNiche(id: 'mn_medical_equipment', categoryId: 'cat_05_health', name: 'Medical Equipment'),
        MicroNiche(id: 'mn_mental_health', categoryId: 'cat_05_health', name: 'Mental Health & Coaching'),
      ],
    ),
    Category(
      id: 'cat_06_home',
      name: 'Home & Living',
      icon: 'home',
      sortOrder: 6,
      microNiches: [
        MicroNiche(id: 'mn_furniture', categoryId: 'cat_06_home', name: 'Furniture'),
        MicroNiche(id: 'mn_interior_decor', categoryId: 'cat_06_home', name: 'Interior Decor'),
        MicroNiche(id: 'mn_kitchen_appliances', categoryId: 'cat_06_home', name: 'Kitchen & Appliances'),
        MicroNiche(id: 'mn_cleaning_supplies', categoryId: 'cat_06_home', name: 'Cleaning Supplies'),
        MicroNiche(id: 'mn_bedding_fabrics', categoryId: 'cat_06_home', name: 'Bedding & Fabrics'),
      ],
    ),
    Category(
      id: 'cat_07_logistics',
      name: 'Logistics & Transport',
      icon: 'local_shipping',
      sortOrder: 7,
      microNiches: [
        MicroNiche(id: 'mn_last_mile_delivery', categoryId: 'cat_07_logistics', name: 'Last-Mile Delivery'),
        MicroNiche(id: 'mn_freight_haulage', categoryId: 'cat_07_logistics', name: 'Freight & Haulage'),
        MicroNiche(id: 'mn_warehousing_storage', categoryId: 'cat_07_logistics', name: 'Warehousing & Storage'),
        MicroNiche(id: 'mn_dispatch_courier', categoryId: 'cat_07_logistics', name: 'Dispatch & Courier'),
        MicroNiche(id: 'mn_vehicle_rentals', categoryId: 'cat_07_logistics', name: 'Vehicle Rentals'),
      ],
    ),
    Category(
      id: 'cat_08_pro_services',
      name: 'Professional Services',
      icon: 'business_center',
      sortOrder: 8,
      microNiches: [
        MicroNiche(id: 'mn_accounting_bookkeeping', categoryId: 'cat_08_pro_services', name: 'Accounting & Bookkeeping'),
        MicroNiche(id: 'mn_legal_services', categoryId: 'cat_08_pro_services', name: 'Legal Services'),
        MicroNiche(id: 'mn_consulting_advisory', categoryId: 'cat_08_pro_services', name: 'Consulting & Advisory'),
        MicroNiche(id: 'mn_marketing_advertising', categoryId: 'cat_08_pro_services', name: 'Marketing & Advertising'),
        MicroNiche(id: 'mn_graphic_design', categoryId: 'cat_08_pro_services', name: 'Graphic Design'),
        MicroNiche(id: 'mn_web_app_dev', categoryId: 'cat_08_pro_services', name: 'Web & App Development'),
        MicroNiche(id: 'mn_photography_video', categoryId: 'cat_08_pro_services', name: 'Photography & Videography'),
      ],
    ),
    Category(
      id: 'cat_09_agriculture',
      name: 'Agriculture & Raw Materials',
      icon: 'eco',
      sortOrder: 9,
      microNiches: [
        MicroNiche(id: 'mn_crop_farming', categoryId: 'cat_09_agriculture', name: 'Crop Farming'),
        MicroNiche(id: 'mn_livestock_poultry', categoryId: 'cat_09_agriculture', name: 'Livestock & Poultry'),
        MicroNiche(id: 'mn_fish_aquaculture', categoryId: 'cat_09_agriculture', name: 'Fish & Aquaculture'),
        MicroNiche(id: 'mn_agro_processing', categoryId: 'cat_09_agriculture', name: 'Agro-Processing'),
        MicroNiche(id: 'mn_farm_inputs', categoryId: 'cat_09_agriculture', name: 'Farm Inputs & Equipment'),
      ],
    ),
    Category(
      id: 'cat_10_education',
      name: 'Education & Training',
      icon: 'school',
      sortOrder: 10,
      microNiches: [
        MicroNiche(id: 'mn_tutoring_testprep', categoryId: 'cat_10_education', name: 'Tutoring & Test Prep'),
        MicroNiche(id: 'mn_pro_certification', categoryId: 'cat_10_education', name: 'Professional Certification'),
        MicroNiche(id: 'mn_online_courses', categoryId: 'cat_10_education', name: 'Online Courses & E-Learning'),
        MicroNiche(id: 'mn_vocational_training', categoryId: 'cat_10_education', name: 'Vocational Training'),
        MicroNiche(id: 'mn_school_supplies', categoryId: 'cat_10_education', name: 'School Supplies & Books'),
      ],
    ),
    Category(
      id: 'cat_11_media',
      name: 'Media & Entertainment',
      icon: 'movie',
      sortOrder: 11,
      microNiches: [
        MicroNiche(id: 'mn_music_production', categoryId: 'cat_11_media', name: 'Music Production'),
        MicroNiche(id: 'mn_event_planning', categoryId: 'cat_11_media', name: 'Event Planning'),
        MicroNiche(id: 'mn_content_creation', categoryId: 'cat_11_media', name: 'Content Creation'),
        MicroNiche(id: 'mn_printing_publishing', categoryId: 'cat_11_media', name: 'Printing & Publishing'),
        MicroNiche(id: 'mn_dj_sound', categoryId: 'cat_11_media', name: 'DJ & Sound Equipment'),
      ],
    ),
    Category(
      id: 'cat_12_construction',
      name: 'Construction & Real Estate',
      icon: 'domain',
      sortOrder: 12,
      microNiches: [
        MicroNiche(id: 'mn_building_materials', categoryId: 'cat_12_construction', name: 'Building Materials'),
        MicroNiche(id: 'mn_property_sales_rentals', categoryId: 'cat_12_construction', name: 'Property Sales & Rentals'),
        MicroNiche(id: 'mn_interior_finishing', categoryId: 'cat_12_construction', name: 'Interior Finishing'),
        MicroNiche(id: 'mn_plumbing_electrical', categoryId: 'cat_12_construction', name: 'Plumbing & Electrical'),
        MicroNiche(id: 'mn_architecture_drafting', categoryId: 'cat_12_construction', name: 'Architecture & Drafting'),
      ],
    ),
  ];

  static List<MicroNiche> getAllMicroNiches() {
    return categories.expand((cat) => cat.microNiches).toList();
  }

  static MicroNiche? findMicroNicheById(String id) {
    for (final cat in categories) {
      for (final mn in cat.microNiches) {
        if (mn.id == id) return mn;
      }
    }
    return null;
  }

  static List<MicroNiche> searchMicroNiches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllMicroNiches();
    return getAllMicroNiches()
        .where((mn) => mn.name.toLowerCase().contains(q))
        .toList();
  }

  static Category? findCategoryForMicroNiche(String microNicheId) {
    for (final cat in categories) {
      for (final mn in cat.microNiches) {
        if (mn.id == microNicheId) return cat;
      }
    }
    return null;
  }
}
