import 'package:flutter/material.dart';

class PlatformAvatar {
  final int id;
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const PlatformAvatar({
    required this.id,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class Avatars {
  static const List<PlatformAvatar> avatarList = [
    PlatformAvatar(id: 1, name: 'Executive', icon: Icons.business_center_rounded, bgColor: Color(0xFFE0E7FF), iconColor: Color(0xFF4338CA)),
    PlatformAvatar(id: 2, name: 'Merchant', icon: Icons.storefront_rounded, bgColor: Color(0xFFD1FAE5), iconColor: Color(0xFF10B981)),
    PlatformAvatar(id: 3, name: 'Strategist', icon: Icons.insights_rounded, bgColor: Color(0xFFFEF3C7), iconColor: Color(0xFFD97706)),
    PlatformAvatar(id: 4, name: 'Tech Lead', icon: Icons.terminal_rounded, bgColor: Color(0xFFE0F2FE), iconColor: Color(0xFF0284C7)),
    PlatformAvatar(id: 5, name: 'Creator', icon: Icons.palette_rounded, bgColor: Color(0xFFFCE7F3), iconColor: Color(0xFFDB2777)),
    PlatformAvatar(id: 6, name: 'Operator', icon: Icons.precision_manufacturing_rounded, bgColor: Color(0xFFF3F4F6), iconColor: Color(0xFF4B5563)),
    PlatformAvatar(id: 7, name: 'Innovator', icon: Icons.lightbulb_rounded, bgColor: Color(0xFFFEF9C3), iconColor: Color(0xFFCA8A04)),
    PlatformAvatar(id: 8, name: 'Connector', icon: Icons.hub_rounded, bgColor: Color(0xFFEDE9FE), iconColor: Color(0xFF7C3AED)),
    PlatformAvatar(id: 9, name: 'Logistics', icon: Icons.local_shipping_rounded, bgColor: Color(0xFFE0F2FE), iconColor: Color(0xFF0369A1)),
    PlatformAvatar(id: 10, name: 'Financier', icon: Icons.account_balance_rounded, bgColor: Color(0xFFDCFCE7), iconColor: Color(0xFF15803D)),
    PlatformAvatar(id: 11, name: 'Chef', icon: Icons.restaurant_rounded, bgColor: Color(0xFFFEE2E2), iconColor: Color(0xFFDC2626)),
    PlatformAvatar(id: 12, name: 'Architect', icon: Icons.architecture_rounded, bgColor: Color(0xFFCFFAFE), iconColor: Color(0xFF0891B2)),
    PlatformAvatar(id: 13, name: 'Analyst', icon: Icons.analytics_rounded, bgColor: Color(0xFFE0E7FF), iconColor: Color(0xFF3730A3)),
    PlatformAvatar(id: 14, name: 'Marketer', icon: Icons.campaign_rounded, bgColor: Color(0xFFFFEDD5), iconColor: Color(0xFFEA580C)),
    PlatformAvatar(id: 15, name: 'Educator', icon: Icons.school_rounded, bgColor: Color(0xFFF5F3FF), iconColor: Color(0xFF6D28D9)),
    PlatformAvatar(id: 16, name: 'Wellness', icon: Icons.spa_rounded, bgColor: Color(0xFFECFDF5), iconColor: Color(0xFF059669)),
    PlatformAvatar(id: 17, name: 'Realtor', icon: Icons.domain_rounded, bgColor: Color(0xFFF1F5F9), iconColor: Color(0xFF334155)),
    PlatformAvatar(id: 18, name: 'Legal', icon: Icons.gavel_rounded, bgColor: Color(0xFFFEF2F2), iconColor: Color(0xFF991B1B)),
    PlatformAvatar(id: 19, name: 'Global', icon: Icons.public_rounded, bgColor: Color(0xFFEFF6FF), iconColor: Color(0xFF2563EB)),
    PlatformAvatar(id: 20, name: 'Square Pro', icon: Icons.verified_rounded, bgColor: Color(0xFFFEF3C7), iconColor: Color(0xFFB45309)),
  ];

  static PlatformAvatar getById(int id) {
    return avatarList.firstWhere((a) => a.id == id, orElse: () => avatarList.first);
  }
}
