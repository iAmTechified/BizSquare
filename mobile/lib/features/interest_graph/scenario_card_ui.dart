import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ScenarioCardScreen extends StatefulWidget {
  const ScenarioCardScreen({super.key});
  @override
  State<ScenarioCardScreen> createState() => _ScenarioCardScreenState();
}

class _ScenarioCardScreenState extends State<ScenarioCardScreen> {
  int _currentIndex = 0;

  static const List<Map<String, dynamic>> _interests = [
    {'emoji': '🛒', 'title': 'Retail & Trade', 'desc': 'Buying and selling physical goods, e-commerce, wholesale'},
    {'emoji': '🍔', 'title': 'Food & Beverage', 'desc': 'Restaurants, catering, food production and delivery'},
    {'emoji': '💼', 'title': 'Professional Services', 'desc': 'Consulting, law, accounting, marketing agencies'},
    {'emoji': '💻', 'title': 'Technology', 'desc': 'Software, IT services, hardware, digital solutions'},
    {'emoji': '🎨', 'title': 'Creative & Media', 'desc': 'Design, photography, content creation, entertainment'},
    {'emoji': '❤️', 'title': 'Health & Wellness', 'desc': 'Healthcare, fitness, beauty, mental health services'},
  ];

  void _nextCard() {
    if (_currentIndex >= _interests.length - 1) {
      context.go('/home');
    } else {
      setState(() => _currentIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _interests[_currentIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text('Select your interests', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('Swipe right to add, left to skip', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (_currentIndex + 1) / _interests.length, backgroundColor: const Color(0xFFE5E7EB), color: const Color(0xFF4338CA)),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))]),
                child: Column(children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 20),
                  Text(item['title']!, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                  const SizedBox(height: 8),
                  Text(item['desc']!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5)),
                ]),
              ),
              const Spacer(),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: _nextCard,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: const BorderSide(color: Color(0xFFE5E7EB))),
                  child: const Text('Skip', style: TextStyle(color: Color(0xFF6B7280))),
                )),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(
                  onPressed: _nextCard,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Add ✓'),
                )),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
