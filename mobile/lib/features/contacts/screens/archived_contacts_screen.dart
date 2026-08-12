import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/unified_contact_model.dart';
import '../../../../core/providers/contacts_state_provider.dart';
import '../../../../core/services/contact_repository.dart';
import '../../../../core/services/avatar_service.dart';
import '../../../../core/widgets/animated_critter_avatar.dart';

class ArchivedContactsScreen extends ConsumerStatefulWidget {
  const ArchivedContactsScreen({super.key});

  @override
  ConsumerState<ArchivedContactsScreen> createState() => _ArchivedContactsScreenState();
}

class _ArchivedContactsScreenState extends ConsumerState<ArchivedContactsScreen> {
  List<UnifiedContactModel> _archived = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchived();
  }

  Future<void> _loadArchived() async {
    setState(() => _isLoading = true);
    final repo = ref.read(contactRepositoryProvider);
    final list = await repo.fetchSquareContacts(includeArchived: true);
    setState(() {
      _archived = list.where((c) => c.isArchived).toList();
      _isLoading = false;
    });
  }

  Future<void> _restoreContact(UnifiedContactModel contact) async {
    final notifier = ref.read(contactsStateProvider.notifier);
    await notifier.restoreContact(contact);
    setState(() {
      _archived.removeWhere((c) => c.id == contact.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.displayName} restored to contacts')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Archived Contacts',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0058FF)))
          : _archived.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArchive,
                        color: Color(0xFF94A3B8),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No archived contacts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _archived.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final contact = _archived[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedCritterAvatar(
                            avatar: AvatarService.getAvatarByIndex(contact.avatarId),
                            size: 40,
                            showGlow: false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  contact.displaySubtitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _restoreContact(contact),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0058FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              'Restore',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
