import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/avatar_service.dart';
import 'animated_critter_avatar.dart';
import 'bizsquare_loader.dart';

class AvatarPickerSheet extends ConsumerStatefulWidget {
  const AvatarPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  @override
  ConsumerState<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<AvatarPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _seedController = TextEditingController();
  String _selectedStyle = 'bottts';
  String _selectedBgColor = 'b6e3f4';
  String _selectedCategory = 'All';
  CritterAvatar? _previewAvatar;

  final List<Map<String, String>> _diceBearStyles = [
    {'id': 'bottts', 'name': 'Robots'},
    {'id': 'bottts-neutral', 'name': 'Droids'},
    {'id': 'croodles', 'name': 'Doodles'},
    {'id': 'thumbs', 'name': 'Thumbs'},
    {'id': 'adventurer', 'name': 'Adventurers'},
    {'id': 'lorelei', 'name': 'Modern'},
  ];

  final List<String> _bgColors = [
    'b6e3f4', // Soft Cyan
    'c0aede', // Soft Lavender
    'd1d4f9', // Soft Indigo
    'ffd5dc', // Soft Rose
    'ffdfbf', // Soft Peach
    'dcfce7', // Soft Emerald
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final active = ref.read(activeAvatarProvider);
    _previewAvatar = active.currentAvatar;
    _seedController.text = 'Founder_${DateTime.now().millisecond}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  void _generateOnlinePreview() {
    final avatarService = ref.read(avatarServiceProvider);
    final url = avatarService.buildDiceBearUrl(
      seed: _seedController.text.trim().isEmpty ? 'BizSquare' : _seedController.text.trim(),
      style: _selectedStyle,
      backgroundColor: _selectedBgColor,
    );

    setState(() {
      _previewAvatar = CritterAvatar(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        name: _seedController.text.trim().isEmpty ? 'New Critter' : _seedController.text.trim(),
        assetPath: '',
        onlineUrl: url,
        personality: 'Custom Generated',
        category: _selectedStyle.toUpperCase(),
        accentColor: const Color(0xFF4338CA),
        isLocal: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatarService = ref.watch(avatarServiceProvider);
    final activeState = ref.watch(activeAvatarProvider);
    final localCritters = avatarService.getLocalCritters();

    final filteredCritters = _selectedCategory == 'All'
        ? localCritters
        : localCritters.where((c) => c.category == _selectedCategory).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Critter',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '24 Offline bundled + Infinite online generator',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stage: Live Preview Showcase
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF8FAFC),
                  (_previewAvatar?.accentColor ?? const Color(0xFF4338CA)).withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (_previewAvatar?.accentColor ?? const Color(0xFF4338CA)).withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                AnimatedCritterAvatar(
                  avatar: _previewAvatar ?? activeState.currentAvatar,
                  size: 76,
                  showGlow: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _previewAvatar?.name ?? activeState.currentAvatar.name,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _previewAvatar?.isLocal == true || (_previewAvatar?.isCachedFile ?? false)
                                  ? 'OFFLINE READY'
                                  : 'ONLINE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _previewAvatar?.personality ?? activeState.currentAvatar.personality,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF4338CA),
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Offline Critters (24)'),
                  Tab(text: 'Online Generator ⚡'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: 24 Offline Bundled Critters
                _buildOfflineTab(filteredCritters, localCritters),

                // TAB 2: Online DiceBear Discovery
                _buildOnlineTab(),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: activeState.isDownloading ? null : _applySelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: activeState.isDownloading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BizSquareLoader(size: 20),
                            SizedBox(width: 12),
                            Text('Caching for Offline Use...'),
                          ],
                        )
                      : Text(
                          _previewAvatar?.isLocal == true
                              ? 'Set As My Critter'
                              : 'Download & Cache for Offline',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineTab(List<CritterAvatar> filteredCritters, List<CritterAvatar> allCritters) {
    final categories = ['All', 'Bot', 'Droid', 'Doodle', 'Thumb', 'Adventurer', 'Lorelei'];

    return Column(
      children: [
        // Category Pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                selectedColor: const Color(0xFF4338CA),
                backgroundColor: const Color(0xFFF3F4F6),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Grid of Offline Avatars
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: filteredCritters.length,
            itemBuilder: (context, index) {
              final critter = filteredCritters[index];
              final isSelected = _previewAvatar?.id == critter.id;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _previewAvatar = critter;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        critter.assetPath,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        critter.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt/Seed Input with Roll button
          Text(
            'Critter Name or Seed',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _seedController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Sparky, AlphaFounder, QuantumFox',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  onSubmitted: (_) => _generateOnlinePreview(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final seeds = ['PixelBolt', 'CyberNova', 'ZenCritter', 'TurboGlow', 'MetaMochi', 'StarFox'];
                  _seedController.text = seeds[DateTime.now().millisecond % seeds.length];
                  _generateOnlinePreview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Icon(Icons.casino_rounded, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Style Selector
          Text(
            'DiceBear Creature Style',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _diceBearStyles.map((style) {
              final isSelected = _selectedStyle == style['id'];
              return ChoiceChip(
                label: Text(style['name']!),
                selected: isSelected,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedStyle = style['id']!);
                  _generateOnlinePreview();
                },
                selectedColor: const Color(0xFF4338CA),
                backgroundColor: const Color(0xFFF3F4F6),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide.none,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Background Palette Selector
          Text(
            'Background Aura Tint',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Row(
            children: _bgColors.map((hex) {
              final color = Color(int.parse('0xFF$hex'));
              final isSelected = _selectedBgColor == hex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBgColor = hex);
                  _generateOnlinePreview();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE5E7EB),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Center(child: Icon(Icons.check, size: 16, color: Color(0xFF4338CA)))
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.download_done_rounded, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'When you apply an online critter, BizSquare automatically downloads it to your phone storage so it animates offline seamlessly.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF15803D), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applySelection() async {
    final notifier = ref.read(activeAvatarProvider.notifier);

    if (_previewAvatar == null) {
      Navigator.pop(context);
      return;
    }

    if (_previewAvatar!.isLocal) {
      await notifier.selectLocalAvatar(_previewAvatar!);
      if (mounted) Navigator.pop(context);
    } else if (_previewAvatar!.onlineUrl != null) {
      final success = await notifier.selectAndCacheOnlineAvatar(
        url: _previewAvatar!.onlineUrl!,
        seed: _seedController.text.trim().isEmpty ? 'Critter' : _seedController.text.trim(),
        style: _selectedStyle,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Critter saved locally for offline use! ✨',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download avatar. Please check connection.')),
          );
        }
      }
    }
  }
}
