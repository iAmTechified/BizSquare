import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/spotlight_model.dart';
import '../../core/services/avatar_service.dart';
import '../../core/services/spotlight_service.dart';
import '../../core/widgets/animated_critter_avatar.dart';
import 'widgets/spotlight_participants_sheet.dart';

class SpotlightHistoryScreen extends ConsumerStatefulWidget {
  const SpotlightHistoryScreen({super.key});

  @override
  ConsumerState<SpotlightHistoryScreen> createState() => _SpotlightHistoryScreenState();
}

class _SpotlightHistoryScreenState extends ConsumerState<SpotlightHistoryScreen> {
  bool _isLoading = true;
  List<SpotlightHistoryItem> _mine = [];
  List<SpotlightHistoryItem> _others = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await ref.read(spotlightServiceProvider).getHistory();
    if (mounted) {
      setState(() {
        _mine = history.mine;
        _others = history.others;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _showDetailSheet(SpotlightHistoryItem item, bool isMine) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMine ? 'My Spotlight Detail' : 'Partner Spotlight Detail',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                _buildStatusChip(item.submissionStatus),
              ],
            ),
            const SizedBox(height: 16),
            if (!isMine && item.creatorName != null) ...[
              Row(
                children: [
                  AnimatedCritterAvatar(
                    avatar: AvatarService.getAvatarByIndex(item.creatorAvatar ?? 1),
                    size: 40,
                    showGlow: false,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.creatorBusinessName ?? item.creatorName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        item.creatorPrimaryOffer ?? 'Verified Member',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(
              item.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.promoText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                height: 1.4,
              ),
            ),
            if (item.caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.caption,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0058FF),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (isMine && item.campaignId.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  SpotlightParticipantsSheet.show(
                    context,
                    campaignId: item.campaignId,
                    campaignTitle: item.title,
                  );
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'View ${item.participantCount} Verified Participants',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = const Color(0xFF10B981).withValues(alpha: 0.15);
    Color text = const Color(0xFF10B981);
    String label = 'Verified';

    if (status == 'pending') {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      text = const Color(0xFFF59E0B);
      label = 'Pending';
    } else if (status == 'needs_changes' || status == 'rejected') {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      text = const Color(0xFFEF4444);
      label = 'Needs Changes';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'Spotlight History',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Mine'),
              Tab(text: 'Others'),
            ],
            labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
            indicatorColor: const Color(0xFF0058FF),
            labelColor: const Color(0xFF0058FF),
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0058FF)))
            : TabBarView(
                children: [
                  // Tab 1: Mine
                  _mine.isEmpty
                      ? _buildEmptyState(
                          icon: HugeIcons.strokeRoundedFlash,
                          title: 'No Spotlight history yet.',
                          subtitle: 'Your Spotlight activity will appear here.',
                          isDark: isDark,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _mine.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = _mine[i];
                            return InkWell(
                              onTap: () => _showDetailSheet(item, true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF161E2E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(item.date),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        _buildStatusChip(item.submissionStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.promoText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const HugeIcon(
                                          icon: HugeIcons.strokeRoundedShare01,
                                          color: Color(0xFF0058FF),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Shared with ${item.participantCount} verified partners',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0058FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // Tab 2: Others
                  _others.isEmpty
                      ? _buildEmptyState(
                          icon: HugeIcons.strokeRoundedShare01,
                          title: 'No Spotlight activity yet.',
                          subtitle: 'Spotlights you receive will appear here.',
                          isDark: isDark,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _others.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = _others[i];
                            return InkWell(
                              onTap: () => _showDetailSheet(item, false),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF161E2E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        AnimatedCritterAvatar(
                                          avatar: AvatarService.getAvatarByIndex(item.creatorAvatar ?? 1),
                                          size: 32,
                                          showGlow: false,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.creatorBusinessName ?? item.creatorName ?? 'Partner',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDate(item.date),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.promoText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState({
    required dynamic icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(icon: icon, color: const Color(0xFF64748B), size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
