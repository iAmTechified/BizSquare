import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/unified_contact_model.dart';
import '../services/contact_repository.dart';
import '../services/contact_sync_cache.dart';
import '../services/contact_sync_engine.dart';
import '../services/device_contacts_adapter.dart';

class ContactsState {
  final int selectedTabIndex; // 0: Square Contacts, 1: All Contacts
  final String searchQuery;
  final bool isSearchActive;
  final ContactLabelModel? activeLabelFilter;
  final bool isSelectionMode;
  final Set<String> selectedContactIds;
  final List<UnifiedContactModel> squareContacts;
  final List<UnifiedContactModel> allContacts;
  final List<ContactLabelModel> labels;
  final List<DuplicateContactPair> duplicatePairs;
  final bool isLoading;
  final bool isOffline;
  final bool hasContactPermission;
  final bool isPermissionPermanentlyDenied;
  final String? expandedContactId;

  const ContactsState({
    this.selectedTabIndex = 0,
    this.searchQuery = '',
    this.isSearchActive = false,
    this.activeLabelFilter,
    this.isSelectionMode = false,
    this.selectedContactIds = const {},
    this.squareContacts = const [],
    this.allContacts = const [],
    this.labels = const [],
    this.duplicatePairs = const [],
    this.isLoading = true,
    this.isOffline = false,
    this.hasContactPermission = false,
    this.isPermissionPermanentlyDenied = false,
    this.expandedContactId,
  });

  // Filtered search results
  List<UnifiedContactModel> get searchResults {
    if (searchQuery.trim().isEmpty) return [];
    final q = searchQuery.toLowerCase().trim();
    final combined = {...allContacts, ...squareContacts}.toList();
    final results = combined.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          c.phoneNumber.contains(q) ||
          (c.businessName?.toLowerCase().contains(q) ?? false) ||
          (c.primaryOffer?.toLowerCase().contains(q) ?? false) ||
          c.labels.any((l) => l.toLowerCase().contains(q));
    }).toList();

    results.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return results;
  }

  // Filtered contacts when in Label View Mode
  List<UnifiedContactModel> get labelFilteredContacts {
    if (activeLabelFilter == null) return [];
    final targetLabel = activeLabelFilter!.name.toLowerCase();
    final combined = {...allContacts, ...squareContacts}.toList();
    final results = combined.where((c) {
      return c.labels.any((l) => l.toLowerCase() == targetLabel);
    }).toList();
    results.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return results;
  }

  ContactsState copyWith({
    int? selectedTabIndex,
    String? searchQuery,
    bool? isSearchActive,
    ContactLabelModel? activeLabelFilter,
    bool clearLabelFilter = false,
    bool? isSelectionMode,
    Set<String>? selectedContactIds,
    List<UnifiedContactModel>? squareContacts,
    List<UnifiedContactModel>? allContacts,
    List<ContactLabelModel>? labels,
    List<DuplicateContactPair>? duplicatePairs,
    bool? isLoading,
    bool? isOffline,
    bool? hasContactPermission,
    bool? isPermissionPermanentlyDenied,
    String? expandedContactId,
    bool clearExpandedId = false,
  }) {
    return ContactsState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      activeLabelFilter: clearLabelFilter ? null : (activeLabelFilter ?? this.activeLabelFilter),
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      squareContacts: squareContacts ?? this.squareContacts,
      allContacts: allContacts ?? this.allContacts,
      labels: labels ?? this.labels,
      duplicatePairs: duplicatePairs ?? this.duplicatePairs,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      hasContactPermission: hasContactPermission ?? this.hasContactPermission,
      isPermissionPermanentlyDenied: isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
      expandedContactId: clearExpandedId ? null : (expandedContactId ?? this.expandedContactId),
    );
  }
}

final contactsStateProvider = StateNotifierProvider<ContactsStateNotifier, ContactsState>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return ContactsStateNotifier(repo);
});

class ContactsStateNotifier extends StateNotifier<ContactsState> {
  final ContactRepository _repository;
  late final ContactSyncEngine _syncEngine;

  ContactsStateNotifier(this._repository) : super(const ContactsState()) {
    _syncEngine = ContactSyncEngine(_repository);
    loadContacts();
  }

  /// Initial load: Cache-first followed by live reconciliation
  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true);

    final hasPerm = await DeviceContactsAdapter.hasPermission();
    final permStatus = await Permission.contacts.status;

    // 1. Fetch Square contacts (from cache or backend)
    final square = await _repository.fetchSquareContacts();
    final labels = await _repository.fetchLabels();

    // 2. Fetch device contacts if permission granted
    List<UnifiedContactModel> all = [];
    if (hasPerm) {
      all = await _repository.fetchUnifiedDeviceContacts(square);
    }

    // 3. Detect duplicate pairs
    final dups = _repository.detectDuplicates(all.isNotEmpty ? all : square);

    state = state.copyWith(
      squareContacts: square,
      allContacts: all,
      labels: labels,
      duplicatePairs: dups,
      hasContactPermission: hasPerm,
      isPermissionPermanentlyDenied: permStatus.isPermanentlyDenied,
      isLoading: false,
    );

    // 4. Background device sync if permission granted
    if (hasPerm && square.isNotEmpty) {
      _syncEngine.syncSquareContactsToDevice(square);
      // Record successful sync timestamp as single source of truth
      await ContactSyncCache.saveLastSyncedAt(DateTime.now());
    }
  }

  Future<void> refresh() async {
    await loadContacts();
  }

  void switchTab(int index) {
    state = state.copyWith(
      selectedTabIndex: index,
      isSearchActive: false,
      clearLabelFilter: true,
    );
  }

  void setSearchActive(bool active) {
    state = state.copyWith(
      isSearchActive: active,
      searchQuery: active ? state.searchQuery : '',
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      isSearchActive: query.isNotEmpty,
    );
  }

  void filterByLabel(ContactLabelModel label) {
    state = state.copyWith(
      activeLabelFilter: label,
      isSearchActive: false,
    );
  }

  void clearLabelFilter() {
    state = state.copyWith(clearLabelFilter: true);
  }

  void toggleCardExpanded(String contactId) {
    if (state.expandedContactId == contactId) {
      state = state.copyWith(clearExpandedId: true);
    } else {
      state = state.copyWith(expandedContactId: contactId);
    }
  }

  // Multi-Selection Mode
  void toggleSelectionMode([bool? enable]) {
    final nextMode = enable ?? !state.isSelectionMode;
    state = state.copyWith(
      isSelectionMode: nextMode,
      selectedContactIds: nextMode ? state.selectedContactIds : {},
    );
  }

  void toggleSelectContact(String contactId) {
    final updated = Set<String>.from(state.selectedContactIds);
    if (updated.contains(contactId)) {
      updated.remove(contactId);
    } else {
      updated.add(contactId);
    }
    state = state.copyWith(
      selectedContactIds: updated,
      isSelectionMode: updated.isNotEmpty,
    );
  }

  void selectAll() {
    final targetList = state.selectedTabIndex == 0 ? state.squareContacts : state.allContacts;
    final allIds = targetList.map((c) => c.id).toSet();
    state = state.copyWith(
      selectedContactIds: allIds,
      isSelectionMode: true,
    );
  }

  void deselectAll() {
    state = state.copyWith(
      selectedContactIds: {},
      isSelectionMode: false,
    );
  }

  // Actions
  Future<void> toggleStar(UnifiedContactModel contact) async {
    final nextStarred = !contact.isStarred;
    _optimisticUpdate(contact.id, (c) => c.copyWith(isStarred: nextStarred));

    if (contact.squareContactId != null) {
      await _repository.updateContact(
        contactId: contact.squareContactId!,
        isStarred: nextStarred,
      );
    }
  }

  Future<void> archiveContact(UnifiedContactModel contact) async {
    _optimisticRemove(contact.id);
    if (contact.squareContactId != null) {
      await _repository.updateContact(
        contactId: contact.squareContactId!,
        isArchived: true,
      );
    }
  }

  Future<void> restoreContact(UnifiedContactModel contact) async {
    if (contact.squareContactId != null) {
      await _repository.updateContact(
        contactId: contact.squareContactId!,
        isArchived: false,
      );
      await loadContacts();
    }
  }

  Future<void> bulkStar(bool star) async {
    final ids = state.selectedContactIds.toList();
    if (ids.isEmpty) return;

    for (final id in ids) {
      _optimisticUpdate(id, (c) => c.copyWith(isStarred: star));
    }
    deselectAll();
    await _repository.bulkUpdate(contactIds: ids, action: star ? 'star' : 'unstar');
  }

  Future<void> bulkArchive() async {
    final ids = state.selectedContactIds.toList();
    if (ids.isEmpty) return;

    for (final id in ids) {
      _optimisticRemove(id);
    }
    deselectAll();
    await _repository.bulkUpdate(contactIds: ids, action: 'archive');
  }

  Future<void> bulkAssignLabel(String labelName) async {
    final ids = state.selectedContactIds.toList();
    if (ids.isEmpty) return;

    for (final id in ids) {
      _optimisticUpdate(id, (c) {
        final existing = List<String>.from(c.labels);
        if (!existing.contains(labelName)) existing.add(labelName);
        return c.copyWith(labels: existing);
      });
    }
    deselectAll();
    await _repository.bulkUpdate(contactIds: ids, action: 'assign_label', labelName: labelName);
    await _repository.fetchLabels();
  }

  Future<void> createLabel(String name, {String color = '#0058FF'}) async {
    final label = await _repository.createLabel(name, color: color);
    if (label != null) {
      state = state.copyWith(labels: [...state.labels, label]);
    }
  }

  Future<void> deleteLabel(String labelId) async {
    await _repository.deleteLabel(labelId);
    state = state.copyWith(
      labels: state.labels.where((l) => l.id != labelId).toList(),
      clearLabelFilter: state.activeLabelFilter?.id == labelId,
    );
  }

  Future<void> mergeDuplicates(String primaryId, String duplicateId) async {
    await _repository.mergeContacts(primaryId, duplicateId);
    await loadContacts();
  }

  Future<void> requestContactsPermission() async {
    final granted = await DeviceContactsAdapter.requestPermission();
    if (granted) {
      await loadContacts();
      // Timestamp recorded in loadContacts() → ContactSyncCache
    } else {
      final permStatus = await Permission.contacts.status;
      state = state.copyWith(
        hasContactPermission: false,
        isPermissionPermanentlyDenied: permStatus.isPermanentlyDenied,
      );
    }
  }

  void _optimisticUpdate(String id, UnifiedContactModel Function(UnifiedContactModel) updater) {
    state = state.copyWith(
      squareContacts: state.squareContacts.map((c) => c.id == id ? updater(c) : c).toList(),
      allContacts: state.allContacts.map((c) => c.id == id ? updater(c) : c).toList(),
    );
  }

  void _optimisticRemove(String id) {
    state = state.copyWith(
      squareContacts: state.squareContacts.where((c) => c.id != id).toList(),
      allContacts: state.allContacts.where((c) => c.id != id).toList(),
    );
  }
}
