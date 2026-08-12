import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/spotlight_model.dart';
import '../../../../core/providers/home_state_provider.dart';
import '../../../../core/widgets/animated_critter_avatar.dart';
import '../../../../core/services/avatar_service.dart';

class SpotlightHomeCard extends ConsumerStatefulWidget {
  final SpotlightCurrentModel? spotlight;

  const SpotlightHomeCard({super.key, this.spotlight});

  @override
  ConsumerState<SpotlightHomeCard> createState() => _SpotlightHomeCardState();
}

class _SpotlightHomeCardState extends ConsumerState<SpotlightHomeCard> {
  bool _isSharing = false;

  Future<void> _shareToWhatsApp() async {
    final spotlight = widget.spotlight;
    if (spotlight == null) return;

    setState(() => _isSharing = true);
    try {
      final text = '${spotlight.content?.promoText ?? "Check out our featured partner on BizSquare!"}\n\n${spotlight.content?.caption ?? "#GrowTogether #BizSquare"}';
      await Share.share(text, subject: spotlight.content?.title ?? 'BizSquare Spotlight');
      await ref.read(homeStateProvider.notifier).participateInCurrentSpotlight();
    } catch (_) {}
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final spotlight = widget.spotlight;
    if (spotlight == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMyTurn = spotlight.isMyTurn;
    final hasParticipated = spotlight.hasParticipated;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with History Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedFlash,
                    color: Color(0xFFFF00A6),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMyTurn ? 'YOUR SPOTLIGHT' : "TODAY'S SPOTLIGHT",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/spotlight/history'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'History',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0058FF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User's Turn State
          if (isMyTurn) ...[
            Text(
              "You're up this week.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "What do you want everyone to share on WhatsApp? Customize your flyer and promotional caption.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${spotlight.targetParticipants} people will participate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0058FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => context.go('/spotlight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add content',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Not User's Turn (Community Spotlight)
            Row(
              children: [
                AnimatedCritterAvatar(
                  avatar: AvatarService.getAvatarByIndex(spotlight.user?.avatarId ?? 1),
                  size: 44,
                  showGlow: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spotlight.user?.businessName ?? 'Community Partner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        spotlight.user?.primaryOffer ?? 'Verified Business',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0058FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              spotlight.content?.promoText ?? 'Help put this verified business in front of your network.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            if (hasParticipated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5AFF00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5AFF00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "You've participated · Shared today",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareToWhatsApp,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedShare01,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _isSharing ? 'Sharing...' : 'Share to WhatsApp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0058FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
