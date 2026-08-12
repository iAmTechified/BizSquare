import 'package:flutter/material.dart';

class PlatformAvatar {
  final int id;
  final String name;
  final String seed;
  final String style;
  final Color bgColor;
  final Color accentColor;

  const PlatformAvatar({
    required this.id,
    required this.name,
    required this.seed,
    this.style = 'bottts',
    required this.bgColor,
    required this.accentColor,
  });

  /// Builds the official DiceBear URL with animated=true query parameter
  String get diceBearUrl {
    final cleanSeed = Uri.encodeComponent(seed.trim());
    return 'https://api.dicebear.com/9.x/$style/png?seed=$cleanSeed&size=256&backgroundColor=b6e3f4&animated=true';
  }
}

class Avatars {
  static const List<PlatformAvatar> avatarList = [
    PlatformAvatar(id: 1, name: 'Executive Critter', seed: 'executive_critter_1', bgColor: Color(0xFFE0E7FF), accentColor: Color(0xFF4338CA)),
    PlatformAvatar(id: 2, name: 'Merchant Critter', seed: 'merchant_critter_2', bgColor: Color(0xFFD1FAE5), accentColor: Color(0xFF10B981)),
    PlatformAvatar(id: 3, name: 'Strategist Critter', seed: 'strategist_critter_3', bgColor: Color(0xFFFEF3C7), accentColor: Color(0xFFD97706)),
    PlatformAvatar(id: 4, name: 'Tech Critter', seed: 'tech_critter_4', bgColor: Color(0xFFE0F2FE), accentColor: Color(0xFF0284C7)),
    PlatformAvatar(id: 5, name: 'Creator Critter', seed: 'creator_critter_5', bgColor: Color(0xFFFCE7F3), accentColor: Color(0xFFDB2777)),
    PlatformAvatar(id: 6, name: 'Operator Critter', seed: 'operator_critter_6', bgColor: Color(0xFFF3F4F6), accentColor: Color(0xFF4B5563)),
    PlatformAvatar(id: 7, name: 'Innovator Critter', seed: 'innovator_critter_7', bgColor: Color(0xFFFEF9C3), accentColor: Color(0xFFCA8A04)),
    PlatformAvatar(id: 8, name: 'Connector Critter', seed: 'connector_critter_8', bgColor: Color(0xFFEDE9FE), accentColor: Color(0xFF7C3AED)),
    PlatformAvatar(id: 9, name: 'Logistics Critter', seed: 'logistics_critter_9', bgColor: Color(0xFFE0F2FE), accentColor: Color(0xFF0369A1)),
    PlatformAvatar(id: 10, name: 'Financier Critter', seed: 'financier_critter_10', bgColor: Color(0xFFDCFCE7), accentColor: Color(0xFF15803D)),
    PlatformAvatar(id: 11, name: 'Chef Critter', seed: 'chef_critter_11', bgColor: Color(0xFFFEE2E2), accentColor: Color(0xFFDC2626)),
    PlatformAvatar(id: 12, name: 'Architect Critter', seed: 'architect_critter_12', bgColor: Color(0xFFCFFAFE), accentColor: Color(0xFF0891B2)),
    PlatformAvatar(id: 13, name: 'Analyst Critter', seed: 'analyst_critter_13', bgColor: Color(0xFFE0E7FF), accentColor: Color(0xFF3730A3)),
    PlatformAvatar(id: 14, name: 'Marketer Critter', seed: 'marketer_critter_14', bgColor: Color(0xFFFFEDD5), accentColor: Color(0xFFEA580C)),
    PlatformAvatar(id: 15, name: 'Educator Critter', seed: 'educator_critter_15', bgColor: Color(0xFFF5F3FF), accentColor: Color(0xFF6D28D9)),
    PlatformAvatar(id: 16, name: 'Wellness Critter', seed: 'wellness_critter_16', bgColor: Color(0xFFECFDF5), accentColor: Color(0xFF059669)),
    PlatformAvatar(id: 17, name: 'Realtor Critter', seed: 'realtor_critter_17', bgColor: Color(0xFFF1F5F9), accentColor: Color(0xFF334155)),
    PlatformAvatar(id: 18, name: 'Legal Critter', seed: 'legal_critter_18', bgColor: Color(0xFFFEF2F2), accentColor: Color(0xFF991B1B)),
    PlatformAvatar(id: 19, name: 'Global Critter', seed: 'global_critter_19', bgColor: Color(0xFFEFF6FF), accentColor: Color(0xFF2563EB)),
    PlatformAvatar(id: 20, name: 'Square Pro Critter', seed: 'square_pro_critter_20', bgColor: Color(0xFFFEF3C7), accentColor: Color(0xFFB45309)),
  ];

  static PlatformAvatar getById(int id) {
    return avatarList.firstWhere((a) => a.id == id, orElse: () => avatarList.first);
  }
}
