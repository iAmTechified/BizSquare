import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/providers/contacts_state_provider.dart';
import 'widgets/contacts_search_bar.dart';
import 'widgets/contact_card.dart';
import 'widgets/square_contacts_tab.dart';
import 'widgets/all_contacts_tab.dart';
import 'widgets/contact_action_sheet.dart';
import 'widgets/merge_duplicates_sheet.dart';
import 'widgets/label_manager_sheet.dart';

class ContactsMainScreen extends ConsumerStatefulWidget {
  const ContactsMainScreen({super.key});

  @override
  ConsumerState<ContactsMainScreen> createState() => _ContactsMainScreenState();
}

class _ContactsMainScreenState extends ConsumerState<ContactsMainScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(contactsStateProvider.notifier).switchTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openActionSheet() {
    final state = ref.read(contactsStateProvider);
    final notifier = ref.read(contactsStateProvider.notifier);

    ContactActionSheet.show(
      context,
      duplicateCount: state.duplicatePairs.length,
      onReviewDuplicates: () => _openMergeSheet(),
      onManageLabels: () => _openLabelsSheet(),
      onSyncNow: () async {
        await notifier.loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts synchronization complete')),
          );
        }
      },
    );
  }

  void _openMergeSheet() {
    final state = ref.read(contactsStateProvider);
    final notifier = ref.read(contactsStateProvider.notifier);

    MergeDuplicatesSheet.show(
      context,
      duplicatePairs: state.duplicatePairs,
      onMerge: (primaryId, duplicateId) async {
        await notifier.mergeDuplicates(primaryId, duplicateId);
      },
    );
  }

  void _openLabelsSheet() {
    final state = ref.read(contactsStateProvider);
    final notifier = ref.read(contactsStateProvider.notifier);

    LabelManagerSheet.show(
      context,
      labels: state.labels,
      onCreateLabel: (name, color) => notifier.createLabel(name, color: color),
      onDeleteLabel: (id) => notifier.deleteLabel(id),
      onSelectLabel: (label) => notifier.filterByLabel(label),
    );
  }

  void _showLabelAssignmentDialog() {
    final state = ref.read(contactsStateProvider);
    final notifier = ref.read(contactsStateProvider.notifier);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Assign Label',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: state.labels.isEmpty
            ? Text(
                'No labels available. Create a label first from the Actions menu.',
                style: GoogleFonts.plusJakartaSans(),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.labels.length,
                  itemBuilder: (ctx, i) {
                    final lbl = state.labels[i];
                    return ListTile(
                      title: Text(lbl.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      onTap: () {
                        Navigator.pop(ctx);
                        notifier.bulkAssignLabel(lbl.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Assigned "${lbl.name}" to selected contacts')),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsStateProvider);
    final notifier = ref.read(contactsStateProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title & Overflow Actions Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contacts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedMoreHorizontal,
                          color: Color(0xFF0058FF),
                          size: 24,
                        ),
                        if (state.duplicatePairs.isNotEmpty)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF0055),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _openActionSheet,
                  ),
                ],
              ),
            ),

            // Search Bar (sits above tabs)
            ContactsSearchBar(
              value: state.searchQuery,
              onChanged: notifier.setSearchQuery,
              onClear: () => notifier.setSearchActive(false),
              onFilterTap: _openLabelsSheet,
            ),

            // Contextual Duplicates Action Banner
            if (state.duplicatePairs.isNotEmpty && !state.isSearchActive && state.activeLabelFilter == null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedUserMultiple,
                      color: Color(0xFF0058FF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${state.duplicatePairs.length} possible duplicate contacts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0058FF),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openMergeSheet,
                      child: Text(
                        'Review & Merge',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0058FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Label View Mode Banner
            if (state.activeLabelFilter != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedTag01,
                      color: Color(0xFF0058FF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Label: ${state.activeLabelFilter!.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                      onPressed: notifier.clearLabelFilter,
                    ),
                  ],
                ),
              ),
            ],

            // Tabs Header (Hidden during Search Mode or Label View Mode)
            if (!state.isSearchActive && state.activeLabelFilter == null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0058FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Square Contacts (${state.squareContacts.length})'),
                    Tab(text: 'All Contacts (${state.allContacts.length})'),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Content Area
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0058FF)))
                  : state.isSearchActive
                      ? _buildSearchResults(state, notifier, isDark)
                      : state.activeLabelFilter != null
                          ? _buildLabelResults(state, notifier, isDark)
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                SquareContactsTab(
                                  contacts: state.squareContacts,
                                  expandedContactId: state.expandedContactId,
                                  isSelectionMode: state.isSelectionMode,
                                  selectedContactIds: state.selectedContactIds,
                                  onRefresh: notifier.refresh,
                                  onCardToggle: notifier.toggleCardExpanded,
                                  onStarToggle: notifier.toggleStar,
                                  onArchive: notifier.archiveContact,
                                  onSelectToggle: (id, _) => notifier.toggleSelectContact(id),
                                  onLongPress: (id) {
                                    notifier.toggleSelectionMode(true);
                                    notifier.toggleSelectContact(id);
                                  },
                                ),
                                AllContactsTab(
                                  contacts: state.allContacts,
                                  hasPermission: state.hasContactPermission,
                                  isPermanentlyDenied: state.isPermissionPermanentlyDenied,
                                  expandedContactId: state.expandedContactId,
                                  isSelectionMode: state.isSelectionMode,
                                  selectedContactIds: state.selectedContactIds,
                                  onRefresh: notifier.refresh,
                                  onRequestPermission: notifier.requestContactsPermission,
                                  onCardToggle: notifier.toggleCardExpanded,
                                  onStarToggle: notifier.toggleStar,
                                  onArchive: notifier.archiveContact,
                                  onSelectToggle: (id, _) => notifier.toggleSelectContact(id),
                                  onLongPress: (id) {
                                    notifier.toggleSelectionMode(true);
                                    notifier.toggleSelectContact(id);
                                  },
                                ),
                              ],
                            ),
            ),

            // Multi-Select Bottom Action Bar
            if (state.isSelectionMode)
              _buildSelectionActionBar(state, notifier, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ContactsState state, ContactsStateNotifier notifier, bool isDark) {
    final results = state.searchResults;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: Color(0xFF94A3B8),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No contacts found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with another name or phone number.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final contact = results[index];
        return ContactCard(
          contact: contact,
          isExpanded: state.expandedContactId == contact.id,
          isSelected: state.selectedContactIds.contains(contact.id),
          isSelectionMode: state.isSelectionMode,
          onTap: () => notifier.toggleCardExpanded(contact.id),
          onLongPress: () {
            notifier.toggleSelectionMode(true);
            notifier.toggleSelectContact(contact.id);
          },
          onStarToggle: () => notifier.toggleStar(contact),
          onArchive: () => notifier.archiveContact(contact),
          onSelectToggle: (val) => notifier.toggleSelectContact(contact.id),
        );
      },
    );
  }

  Widget _buildLabelResults(ContactsState state, ContactsStateNotifier notifier, bool isDark) {
    final results = state.labelFilteredContacts;
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No contacts in this label yet.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final contact = results[index];
        return ContactCard(
          contact: contact,
          isExpanded: state.expandedContactId == contact.id,
          isSelected: state.selectedContactIds.contains(contact.id),
          isSelectionMode: state.isSelectionMode,
          onTap: () => notifier.toggleCardExpanded(contact.id),
          onLongPress: () {
            notifier.toggleSelectionMode(true);
            notifier.toggleSelectContact(contact.id);
          },
          onStarToggle: () => notifier.toggleStar(contact),
          onArchive: () => notifier.archiveContact(contact),
          onSelectToggle: (val) => notifier.toggleSelectContact(contact.id),
        );
      },
    );
  }

  Widget _buildSelectionActionBar(ContactsState state, ContactsStateNotifier notifier, bool isDark) {
    final count = state.selectedContactIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '$count selected',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: notifier.selectAll,
              child: const Text('Select all'),
            ),
            const Spacer(),

            // Star
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedStar, color: Color(0xFFF59E0B), size: 20),
              onPressed: () => notifier.bulkStar(true),
            ),

            // Assign Label
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedTag01, color: Color(0xFF0058FF), size: 20),
              onPressed: _showLabelAssignmentDialog,
            ),

            // Archive
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedArchive, color: Color(0xFFFF0055), size: 20),
              onPressed: () async {
                await notifier.bulkArchive();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count contacts archived')),
                  );
                }
              },
            ),

            // Close Selection
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Color(0xFF94A3B8), size: 20),
              onPressed: notifier.deselectAll,
            ),
          ],
        ),
      ),
    );
  }
}
