import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/data/micro_niche_taxonomy.dart';
import '../../../core/providers/profile_state_provider.dart';

class ManageOffersScreen extends ConsumerStatefulWidget {
  const ManageOffersScreen({super.key});

  @override
  ConsumerState<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends ConsumerState<ManageOffersScreen> {
  String? _primaryMicroNicheId;
  final Set<String> _secondaryMicroNicheIds = {};
  String _searchQuery = '';
  String? _expandedCategoryId;
  bool _isSelectingPrimaryMode = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileStateProvider).profile;
    _primaryMicroNicheId = profile?.primaryOffer?.microNicheId;
    _secondaryMicroNicheIds.addAll(
      profile?.secondaryOffers.map((s) => s.microNicheId) ?? [],
    );
    _expandedCategoryId = MicroNicheTaxonomy.categories.first.id;
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _selectPrimary(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _primaryMicroNicheId = id;
      _isSelectingPrimaryMode = false;
    });
    _markChanged();
  }

  void _toggleSecondary(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_secondaryMicroNicheIds.contains(id)) {
        _secondaryMicroNicheIds.remove(id);
      } else {
        if (_secondaryMicroNicheIds.length < 2) {
          _secondaryMicroNicheIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum 2 secondary offerings allowed.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
    _markChanged();
  }

  Future<void> _handleSave() async {
    if (_primaryMicroNicheId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a primary business offering.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(profileStateProvider.notifier).updateOffers(
      primaryMicroNicheId: _primaryMicroNicheId!,
      secondaryMicroNicheIds: _secondaryMicroNicheIds.toList(),
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Business offerings updated successfully',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(profileStateProvider);
    final categories = MicroNicheTaxonomy.categories;

    final primaryNiche = _primaryMicroNicheId != null
        ? MicroNicheTaxonomy.findMicroNicheById(_primaryMicroNicheId!)
        : null;

    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchResults = isSearching
        ? MicroNicheTaxonomy.searchMicroNiches(_searchQuery)
        : <MicroNiche>[];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF0058FF),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Business & Offers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Subtitle
                    Text(
                      'Manage what your business supplies to the community. Contact Gain uses these to match verified buyers with your inventory.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SECTION 1: PRIMARY OFFER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSelectingPrimaryMode
                              ? const Color(0xFF0058FF)
                              : isDark
                                  ? const Color(0xFF2A364F)
                                  : const Color(0xFFE2E8F0),
                          width: _isSelectingPrimaryMode ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedCrown,
                                  color: Color(0xFFF59E0B),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Primary Offer',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      "What's the main thing you sell or offer?",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isSelectingPrimaryMode = true);
                                },
                                child: Text(
                                  _isSelectingPrimaryMode ? 'Selecting' : 'Change',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0058FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (primaryNiche != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF0058FF).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                                    color: Color(0xFF0058FF),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    primaryNiche.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0058FF),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'No primary offer selected yet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SECTION 2: SECONDARY OFFERS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !_isSelectingPrimaryMode
                              ? const Color(0xFF0058FF)
                              : isDark
                                  ? const Color(0xFF2A364F)
                                  : const Color(0xFFE2E8F0),
                          width: !_isSelectingPrimaryMode ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedLayers01,
                                  color: Color(0xFF10B981),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Other things you offer',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Additional things you sell. Not your main offer. (Max 2)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isSelectingPrimaryMode = false);
                                },
                                child: Text(
                                  !_isSelectingPrimaryMode ? 'Selecting' : 'Edit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0058FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_secondaryMicroNicheIds.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _secondaryMicroNicheIds.map((id) {
                                final niche = MicroNicheTaxonomy.findMicroNicheById(id);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        niche?.name ?? id,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _toggleSecondary(id),
                                        child: const HugeIcon(
                                          icon: HugeIcons.strokeRoundedCancel01,
                                          color: Color(0xFFEF4444),
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              'No secondary offerings added.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Search & Taxonomy Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: _isSelectingPrimaryMode
                                    ? 'Search main offering...'
                                    : 'Search secondary offerings...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchQuery = ''),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: Color(0xFF64748B),
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Target Selection Mode Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isSelectingPrimaryMode
                            ? const Color(0xFF0058FF).withValues(alpha: 0.08)
                            : const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: _isSelectingPrimaryMode
                                ? HugeIcons.strokeRoundedCrown
                                : HugeIcons.strokeRoundedLayers01,
                            color: _isSelectingPrimaryMode
                                ? const Color(0xFF0058FF)
                                : const Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSelectingPrimaryMode
                                ? 'Selecting Main Primary Offer'
                                : 'Selecting Secondary Offers (${_secondaryMicroNicheIds.length}/2)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _isSelectingPrimaryMode
                                  ? const Color(0xFF0058FF)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Search Results or Category List
                    if (isSearching) ...[
                      if (searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No matching offerings found.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: searchResults.map((mn) => _buildNicheTile(mn, isDark)).toList(),
                        ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final cat = categories[idx];
                          final isExpanded = _expandedCategoryId == cat.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161E2E) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _expandedCategoryId = isExpanded ? null : cat.id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        HugeIcon(
                                          icon: isExpanded
                                              ? HugeIcons.strokeRoundedArrowUp01
                                              : HugeIcons.strokeRoundedArrowDown01,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: cat.microNiches
                                          .map((mn) => _buildNicheTile(mn, isDark))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Fixed Save Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0058FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Save Offerings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNicheTile(MicroNiche mn, bool isDark) {
    final isPrimary = _primaryMicroNicheId == mn.id;
    final isSecondary = _secondaryMicroNicheIds.contains(mn.id);

    Color bg;
    Color border;
    Color text;

    if (isPrimary) {
      bg = const Color(0xFF0058FF);
      border = const Color(0xFF0058FF);
      text = Colors.white;
    } else if (isSecondary) {
      bg = const Color(0xFF10B981);
      border = const Color(0xFF10B981);
      text = Colors.white;
    } else {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      text = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    }

    return InkWell(
      onTap: () {
        if (_isSelectingPrimaryMode) {
          _selectPrimary(mn.id);
        } else {
          _toggleSecondary(mn.id);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Text(
          mn.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
      ),
    );
  }
}
