import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/interest_taxonomy_model.dart';
import '../../core/services/interest_service.dart';

class MyInterestsScreen extends ConsumerStatefulWidget {
  const MyInterestsScreen({super.key});

  @override
  ConsumerState<MyInterestsScreen> createState() => _MyInterestsScreenState();
}

class _MyInterestsScreenState extends ConsumerState<MyInterestsScreen> {
  bool _isLoading = true;
  List<InterestTaxonomyModel> _taxonomies = [];
  Set<String> _selectedTaxonomyIds = {};
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
        _selectedTaxonomyIds = baselineList.map((b) => b['id'].toString()).toSet();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleInterest(String taxonomyId) async {
    setState(() {
      if (_selectedTaxonomyIds.contains(taxonomyId)) {
        _selectedTaxonomyIds.remove(taxonomyId);
      } else {
        _selectedTaxonomyIds.add(taxonomyId);
      }
    });

    // Auto-save changes to backend
    setState(() => _isSaving = true);
    final interestService = ref.read(interestServiceProvider);
    await interestService.updateBaselineInterests(_selectedTaxonomyIds.toList());
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Interests',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0058FF)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0058FF)))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0058FF).withValues(alpha: 0.1),
                          const Color(0xFF5AFF00).withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0058FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Baseline Interests',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select core categories to anchor your profile. Daily wall interactions continuously tune your current demand.',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected Count Header
                  Text(
                    '${_selectedTaxonomyIds.length} SELECTED CATEGORIES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0058FF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Taxonomy Hierarchy List
                  ..._taxonomies.map((parent) => _buildCategorySection(parent)),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySection(InterestTaxonomyModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0058FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.category_rounded, color: Color(0xFF0058FF), size: 20),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Text(
          '${category.children.length} subcategories',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.children.map((child) {
                final isSelected = _selectedTaxonomyIds.contains(child.id);
                return FilterChip(
                  label: Text(child.name),
                  selected: isSelected,
                  onSelected: (_) => _toggleInterest(child.id),
                  selectedColor: const Color(0xFF0058FF),
                  checkmarkColor: Colors.white,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0058FF) : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
