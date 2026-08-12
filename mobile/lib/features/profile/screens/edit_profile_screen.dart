import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/providers/profile_state_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../core/widgets/animated_critter_avatar.dart';
import '../../../core/widgets/avatar_picker_sheet.dart';
import '../../../core/widgets/bizsquare_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _fullNameController;
  int _avatarId = 1;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileStateProvider).profile;
    _businessNameController = TextEditingController(text: profile?.businessName ?? '');
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _avatarId = profile?.avatarId ?? 1;

    _businessNameController.addListener(_onFieldChanged);
    _fullNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final profile = ref.read(profileStateProvider).profile;
    final changed = _businessNameController.text.trim() != (profile?.businessName ?? '') ||
        _fullNameController.text.trim() != (profile?.fullName ?? '') ||
        _avatarId != (profile?.avatarId ?? 1);

    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _openAvatarPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerSheet(
        currentAvatarId: _avatarId,
        onAvatarSelected: (newId) {
          setState(() {
            _avatarId = newId;
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final success = await ref.read(profileStateProvider.notifier).updateProfileIdentity(
          businessName: _businessNameController.text.trim(),
          fullName: _fullNameController.text.trim(),
          avatarId: _avatarId,
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Discard changes?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Editing',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Discard',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(profileStateProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
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
            onPressed: () async {
              if (_hasChanges) {
                final pop = await _onWillPop();
                if (pop && context.mounted) context.pop();
              } else {
                context.pop();
              }
            },
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _openAvatarPicker,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0058FF).withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                ),
                                child: AnimatedCritterAvatar(
                                  avatar: AvatarService.getAvatarByIndex(_avatarId),
                                  size: 96,
                                  showGlow: false,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0058FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedCamera01,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _openAvatarPicker,
                          child: Text(
                            'Change Critter Avatar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0058FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error Banner
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Business Name Input
                  BizSquareTextField(
                    label: 'Business / Brand Name',
                    controller: _businessNameController,
                    hintText: 'e.g. Acme Tech Solutions',
                    prefixIcon: HugeIcons.strokeRoundedStore01,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Business name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Owner Full Name Input
                  BizSquareTextField(
                    label: 'Owner / Contact Name',
                    controller: _fullNameController,
                    hintText: 'e.g. Jane Doe',
                    prefixIcon: HugeIcons.strokeRoundedUser,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Owner name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone Number (Read-only)
                  BizSquareTextField(
                    label: 'Registered Phone Number',
                    controller: TextEditingController(text: state.profile?.phoneNumber ?? ''),
                    prefixIcon: HugeIcons.strokeRoundedCall02,
                    enabled: false,
                    helperText: 'Phone number is bound to your account identity.',
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (state.isSaving || !_hasChanges) ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0058FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                              'Save Changes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
