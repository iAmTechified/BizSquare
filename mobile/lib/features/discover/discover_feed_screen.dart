import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});
  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _filter = 0;
  final List<String> _filters = ['All', 'Recommended', 'Featured', 'Nearby'];

  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  static const List<Map<String, String>> _businesses = [
    {'name': 'Sunshine Bakery', 'category': 'Food & Beverage', 'city': 'Lagos', 'rating': '4.8', 'matches': '127'},
    {'name': 'TechBridge Solutions', 'category': 'Technology', 'city': 'Abuja', 'rating': '4.6', 'matches': '89'},
    {'name': 'Creative Hub Studio', 'category': 'Creative & Media', 'city': 'Port Harcourt', 'rating': '4.9', 'matches': '203'},
    {'name': 'Apex Logistics', 'category': 'Logistics', 'city': 'Kano', 'rating': '4.5', 'matches': '74'},
    {'name': 'Green Leaf Pharmacy', 'category': 'Health & Wellness', 'city': 'Ibadan', 'rating': '4.7', 'matches': '156'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: const Color(0xFF4338CA),
          labelColor: const Color(0xFF4338CA),
          unselectedLabelColor: const Color(0xFF6B7280),
          tabs: const [Tab(text: 'Businesses'), Tab(text: 'People'), Tab(text: 'Products'), Tab(text: 'Services')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // Businesses Tab
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(decoration: InputDecoration(hintText: 'Search businesses...', prefixIcon: const Icon(Icons.search_outlined), filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 36, child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _filter == i ? const Color(0xFF4338CA) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                  child: Text(_filters[i], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _filter == i ? Colors.white : const Color(0xFF6B7280))),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _businesses.length,
            itemBuilder: (_, i) => _BusinessCard(data: _businesses[i]),
          )),
        ]),
        Center(child: Text('People coming soon', style: GoogleFonts.inter(color: const Color(0xFF6B7280)))),
        Center(child: Text('Products coming soon', style: GoogleFonts.inter(color: const Color(0xFF6B7280)))),
        Center(child: Text('Services coming soon', style: GoogleFonts.inter(color: const Color(0xFF6B7280)))),
      ]),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final Map<String, String> data;
  const _BusinessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        CircleAvatar(radius: 28, backgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.1), child: const Icon(Icons.storefront_outlined, color: Color(0xFF4338CA), size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 2),
          Text('${data['category']} · ${data['city']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(data['rating']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            const Icon(Icons.people_outline, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 3),
            Text('${data['matches']} matched', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10B981))),
          ]),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF4338CA).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Text('Connect', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)))),
      ]),
    );
  }
}
