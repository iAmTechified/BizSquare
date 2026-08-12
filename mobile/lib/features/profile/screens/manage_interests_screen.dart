import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/interest_taxonomy_model.dart';
import '../../../core/providers/profile_state_provider.dart';
import '../../../core/services/interest_service.dart';
import '../../../core/widgets/shimmer_loading.dart';

class ManageInterestsScreen extends ConsumerStatefulWidget {
  const ManageInterestsScreen({super.key});

  @override
  ConsumerState<ManageInterestsScreen> createState() => _ManageInterestsScreenState();
}

class _ManageInterestsScreenState extends ConsumerState<ManageInterestsScreen> {
  bool _isLoading = true;
  List<InterestTaxonomyModel> _taxonomies = [];
  final Set<String> _selectedTaxonomyIds = {};
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final interestService = ref.read(interestServiceProvider);
    final results = await Future.wait([
      interestService.fetchTaxonomies(),
      interestService.fetchBaselineInterests(),
    ]);

    if (mounted) {
      final taxList = results[0] as List<InterestTaxonomyModel>;
      final baselineList = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _taxonomies = taxList;
        _selectedTaxonomyIds.addAll(
          baselineList.map((b) => b['id'].toString()),
        );
        _isLoading = false;
      });
    }
  }

  void _toggleInterest(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTaxonomyIds.contains(id)) {
        _selectedTaxonomyIds.remove(id);
      } else {
        _selectedTaxonomyIds.add(id);
      }
    });
  }

  Future<void> _handleSave() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final success = await ref
        .read(profileStateProvider.notifier)
        .updateInterests(_selectedTaxonomyIds.toList());

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Interests updated successfully',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredTaxonomies = _taxonomies.where((t) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.name.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false);
    }).toList();

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
          'Your Interests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? ShimmerLoading(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      const ShimmerBox(height: 50, width: double.infinity, borderRadius: 14),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: 8,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, __) =>
                              const ShimmerCard(height: 64, borderRadius: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Explanatory Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161E2E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedTarget02,
                                  color: Color(0xFF0058FF),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Explicit Baseline Interests',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'These are interests you explicitly set to guide which trade contacts and inventory you receive in your weekly gain cycle.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Search Bar
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
                                      hintText: 'Search interest categories...',
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

                          const SizedBox(height: 14),

                          // Selected Summary Chip
                          Text(
                            '${_selectedTaxonomyIds.length} Selected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0058FF),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Taxonomy Items
                          if (filteredTaxonomies.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No matching categories found.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredTaxonomies.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tax = filteredTaxonomies[index];
                                final isSelected = _selectedTaxonomyIds.contains(tax.id);

                                return InkWell(
                                  onTap: () => _toggleInterest(tax.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0058FF).withValues(alpha: 0.1)
                                          : isDark
                                              ? const Color(0xFF161E2E)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0058FF)
                                            : isDark
                                                ? const Color(0xFF2A364F)
                                                : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        HugeIcon(
                                          icon: isSelected
                                              ? HugeIcons.strokeRoundedCheckmarkBadge01
                                              : HugeIcons.strokeRoundedCircle,
                                          color: isSelected
                                              ? const Color(0xFF0058FF)
                                              : const Color(0xFF94A3B8),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tax.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              if (tax.description != null && tax.description!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  tax.description!,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Save Button
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
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0058FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Save Interests',
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
}
