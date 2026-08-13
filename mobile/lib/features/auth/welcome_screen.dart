import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const List<_Feature> _features = [
    _Feature(Icons.people_alt_outlined, 'Smart Community', 'Get matched with the right businesses daily'),
    _Feature(Icons.contacts_outlined, 'Pocket CRM', 'Turn every contact into a business opportunity'),
    _Feature(Icons.trending_up_outlined, 'Visibility Tools', 'Grow your reach through WhatsApp & Spotlight'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                  ),
                  child: Image.asset(
                    'assets/icons/bizsquare_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.widgets_rounded, size: 20, color: Color(0xFF4338CA)),
                  ),
                ),
                const SizedBox(width: 10),
                Text('BizSquare', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 48),
              Text('Grow your\nbusiness\ntogether.', style: GoogleFonts.inter(fontSize: 38, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 12),
              Text('The WhatsApp-first platform for smart\nbusiness community and growth.', style: GoogleFonts.inter(fontSize: 15, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), height: 1.5)),
              const SizedBox(height: 40),
              ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF4338CA).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(f.icon, size: 20, color: const Color(0xFF4338CA))),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(f.subtitle, style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  ]),
                ]),
              )),
              const Spacer(),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.go('/register-steps'), child: const Text('Get Started'))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFF4338CA))),
                child: Text('I already have an account', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF4338CA))),
              )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);
}
