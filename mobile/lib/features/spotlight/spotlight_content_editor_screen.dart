import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/home_state_provider.dart';
import '../../core/services/spotlight_service.dart';

class SpotlightContentEditorScreen extends ConsumerStatefulWidget {
  const SpotlightContentEditorScreen({super.key});

  @override
  ConsumerState<SpotlightContentEditorScreen> createState() => _SpotlightContentEditorScreenState();
}

class _SpotlightContentEditorScreenState extends ConsumerState<SpotlightContentEditorScreen> {
  final _titleController = TextEditingController();
  final _promoController = TextEditingController();
  final _captionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final spotlight = ref.read(homeStateProvider).spotlight;
    _titleController.text = spotlight?.content?.title ?? 'Featured Business Spotlight';
    _promoController.text = spotlight?.content?.promoText ?? '';
    _captionController.text = spotlight?.content?.caption ?? '#GrowTogether #BizSquare';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promoController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    final title = _titleController.text.trim();
    final promo = _promoController.text.trim();
    final caption = _captionController.text.trim();

    if (title.isEmpty || promo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and promo description.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await ref.read(spotlightServiceProvider).setMyContent(
          title: title,
          promoText: promo,
          caption: caption,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        await ref.read(homeStateProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Spotlight content updated successfully!')),
          );
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Customize Spotlight',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Title',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Lagos Wholesale Hub Spotlight',
                filled: true,
                fillColor: isDark ? const Color(0xFF161E2E) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Promotional Text for WhatsApp Status',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promoController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what products or services your network should reach out to you for...',
                filled: true,
                fillColor: isDark ? const Color(0xFF161E2E) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Hashtags & Caption',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: '#GrowTogether #BizSquare',
                filled: true,
                fillColor: isDark ? const Color(0xFF161E2E) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save & Set Live',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
