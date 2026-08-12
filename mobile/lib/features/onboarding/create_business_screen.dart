import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});
  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  String? _selectedCategory;
  final List<String> _categories = ['Retail & Trade', 'Food & Beverage', 'Professional Services', 'Technology', 'Creative & Media', 'Health & Wellness', 'Education', 'Real Estate', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(backgroundColor: const Color(0xFFFAFAFA), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Set up your\nbusiness 🏪', style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: const Color(0xFF111827), height: 1.2)),
              const SizedBox(height: 8),
              Text('Tell us about your business to get started', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF6B7280))),
              const SizedBox(height: 36),
              TextFormField(decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.storefront_outlined))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Business Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  filled: true, fillColor: const Color(0xFFF9FAFB),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'City / Location', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 16),
              TextFormField(maxLines: 3, decoration: const InputDecoration(labelText: 'Business Description', alignLabelWithHint: true, prefixIcon: Icon(Icons.description_outlined))),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.go('/interest-graph'), child: const Text('Next →'))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
