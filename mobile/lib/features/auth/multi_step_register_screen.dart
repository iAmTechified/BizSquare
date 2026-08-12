import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/data/micro_niche_taxonomy.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../core/widgets/animated_critter_avatar.dart';
import '../../core/widgets/avatar_picker_sheet.dart';
import '../../core/widgets/bizsquare_text_field.dart';
import '../../core/services/avatar_service.dart';

class MultiStepRegisterScreen extends ConsumerStatefulWidget {
  const MultiStepRegisterScreen({super.key});

  @override
  ConsumerState<MultiStepRegisterScreen> createState() => _MultiStepRegisterScreenState();
}

class _MultiStepRegisterScreenState extends ConsumerState<MultiStepRegisterScreen> {
  int _step = 1;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 Controllers
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 Micro-Niche State (Two-Step Collapsible Accordion & Mutual Exclusion)
  String? _primaryMicroNicheId;
  final Set<String> _secondaryMicroNicheIds = {};
  String _nicheSearchQuery = '';
  String? _expandedCategoryId;
  bool _isSelectingPrimaryMode = true;

  // Step 3 Verification Code Controller
  final _verificationCodeController = TextEditingController();

  // Step 4 Security PIN Controller
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();

  // Step 5 Username & Interests
  final _usernameController = TextEditingController();
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _usernameDebounce;
  final Set<String> _selectedInterestIds = {};

  @override
  void initState() {
    super.initState();
    _restoreDraftState();
  }

  void _restoreDraftState() {
    final draft = ref.read(onboardingDraftProvider);
    _step = draft.currentStep;
    _businessNameController.text = draft.businessName ?? '';
    _phoneController.text = draft.phoneNumber ?? '';

    _primaryMicroNicheId = draft.primaryMicroNicheId;
    _secondaryMicroNicheIds.clear();
    for (final id in draft.selectedMicroNicheIds) {
      if (id != _primaryMicroNicheId) {
        _secondaryMicroNicheIds.add(id);
      }
    }

    if (_primaryMicroNicheId == null && draft.selectedMicroNicheIds.isNotEmpty) {
      _primaryMicroNicheId = draft.selectedMicroNicheIds.first;
    }

    _isSelectingPrimaryMode = _primaryMicroNicheId == null;

    _verificationCodeController.text = draft.verificationCode ?? '';
    _pinController.text = draft.pin ?? '';
    _usernameController.text = draft.username ?? '';
    _selectedInterestIds.addAll(draft.selectedInterestIds);

    _expandedCategoryId = MicroNicheTaxonomy.categories.first.id;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    _usernameController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String val) {
    _usernameDebounce?.cancel();
    final clean = val.trim().replaceAll('@', '');
    if (clean.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);
    _usernameDebounce = Timer(const Duration(milliseconds: 400), () async {
      final api = ref.read(apiServiceProvider);
      final available = await api.checkUsernameAvailable(clean);
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
        });
      }
    });
  }

  List<String> get _allSelectedMicroNiches {
    final list = <String>[];
    if (_primaryMicroNicheId != null) {
      list.add(_primaryMicroNicheId!);
    }
    for (final id in _secondaryMicroNicheIds) {
      if (!list.contains(id)) list.add(id);
    }
    return list;
  }

  Future<void> _handleNext() async {
    setState(() => _errorMessage = null);
    HapticFeedback.mediumImpact();

    if (_step == 1) {
      final bName = _businessNameController.text.trim();
      final phone = _phoneController.text.trim();

      if (bName.isEmpty) {
        setState(() => _errorMessage = 'Please enter your business or store name.');
        return;
      }
      if (phone.isEmpty) {
        setState(() => _errorMessage = 'Please enter your WhatsApp phone number.');
        return;
      }

      final normalized = PhoneNormalizer.normalize(phone);
      if (normalized.isEmpty) {
        setState(() => _errorMessage = 'Please enter a valid phone number.');
        return;
      }

      await ref.read(onboardingDraftProvider.notifier).updateStep1(
        businessName: bName,
        phoneNumber: normalized,
        avatarId: 1,
      );

      setState(() => _step = 2);
    } else if (_step == 2) {
      if (_primaryMicroNicheId == null) {
        setState(() => _errorMessage = 'Please choose the main thing you sell first.');
        return;
      }

      final allNiches = _allSelectedMicroNiches;
      await ref.read(onboardingDraftProvider.notifier).updateStep2(
        microNicheIds: allNiches,
        primaryMicroNicheId: _primaryMicroNicheId!,
      );

      setState(() => _step = 3);
    } else if (_step == 3) {
      final code = _verificationCodeController.text.trim().toUpperCase();
      if (code.isEmpty || code.length < 4) {
        setState(() => _errorMessage = 'Please enter the setup passcode.');
        return;
      }

      setState(() => _isLoading = true);
      final draft = ref.read(onboardingDraftProvider);
      final api = ref.read(apiServiceProvider);
      final allNiches = _allSelectedMicroNiches;

      try {
        final result = await api.verifyAndRegister(
          code: code,
          phoneNumber: _phoneController.text.trim(),
          businessName: _businessNameController.text.trim(),
          avatarId: draft.selectedAvatarId,
          microNicheIds: allNiches,
          primaryMicroNicheId: _primaryMicroNicheId!,
        );

        final token = result['token'] as String;
        final user = result['user'] as Map<String, dynamic>;

        await ref.read(userStateProvider.notifier).completeVerification(
          token: token,
          businessName: user['business_name'] as String? ?? _businessNameController.text.trim(),
          phoneNumber: user['phone_number'] as String? ?? _phoneController.text.trim(),
          avatarId: user['avatar_id'] as int? ?? 1,
          supplyMicroNicheIds: allNiches,
          primaryMicroNicheId: _primaryMicroNicheId!,
        );

        await ref.read(onboardingDraftProvider.notifier).updateStep3Verified(verificationCode: code);

        setState(() {
          _isLoading = false;
          _step = 4;
        });
      } on ApiException catch (e) {
        debugPrint('Register verify error: ${e.message}');
        setState(() {
          _isLoading = false;
          if (e.code == 'INVALID_CODE') {
            _errorMessage = 'Invalid Passcode. In dev mode, please use B41230.';
          } else if (e.code == 'CODE_ALREADY_USED') {
            _errorMessage = 'This passcode has already been claimed.';
          } else if (e.code == 'CODE_EXPIRED') {
            _errorMessage = 'This passcode has expired. In dev mode, please use B41230.';
          } else if (e.code == 'PHONE_ALREADY_REGISTERED') {
            _errorMessage = 'This phone number is already registered. Please sign in instead.';
          } else {
            _errorMessage = 'Unable to verify passcode. Please check and try again.';
          }
        });
      } catch (e) {
        debugPrint('Register unexpected error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error. Please check your internet and try again.';
        });
      }
    } else if (_step == 4) {
      final pin = _pinController.text.trim();
      final pinConfirm = _pinConfirmController.text.trim();

      if (pin.length != 4) {
        setState(() => _errorMessage = 'PIN must be exactly 4 digits.');
        return;
      }
      if (pin != pinConfirm) {
        setState(() => _errorMessage = 'PINs do not match. Please re-enter.');
        return;
      }

      await ref.read(onboardingDraftProvider.notifier).updateStep4Pin(pin: pin);
      setState(() => _step = 5);
    } else if (_step == 5) {
      final username = _usernameController.text.trim().replaceAll('@', '');
      if (username.length < 3) {
        setState(() => _errorMessage = 'Username must be at least 3 characters.');
        return;
      }
      if (_isUsernameAvailable == false) {
        setState(() => _errorMessage = 'Username is already taken. Please choose another.');
        return;
      }
      if (_selectedInterestIds.isEmpty) {
        setState(() => _errorMessage = 'Please select at least 1 product interest for weekly matching.');
        return;
      }

      setState(() => _isLoading = true);
      final api = ref.read(apiServiceProvider);

      try {
        await api.completeOnboarding(
          username: username,
          pin: _pinController.text.trim(),
          interestMicroNicheIds: _selectedInterestIds.toList(),
        );

        await ref.read(userStateProvider.notifier).completeOnboarding(
          username: username,
          baselineDemandIds: _selectedInterestIds.toList(),
        );

        await ref.read(onboardingDraftProvider.notifier).clearDraft();

        if (mounted) {
          setState(() => _isLoading = false);
          context.go('/daily-wall');
        }
      } on ApiException catch (e) {
        debugPrint('Complete onboarding API error: ${e.message}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to complete setup. Please check your details and retry.';
        });
      } catch (e) {
        debugPrint('Complete onboarding error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to complete registration. Please check your internet.';
        });
      }
    }
  }

  void _handleBack() {
    setState(() => _errorMessage = null);
    if (_step > 1 && _step != 4) {
      setState(() => _step--);
    } else if (_step == 1) {
      context.go('/auth-wall');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              _handleBack();
            },
          ),
          title: Text(
            'Step $_step of 5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Line
              Container(
                height: 3,
                width: double.infinity,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_step / 5).clamp(0.0, 1.0),
                  child: Container(color: const Color(0xFF0058FF)),
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Friendly Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
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
                                  _errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
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

                      // Render Current Step
                      if (_step == 1) _buildStep1BusinessInfo(isDark),
                      if (_step == 2) _buildStep2OffersDifferentiation(isDark),
                      if (_step == 3) _buildStep3SetupCode(isDark),
                      if (_step == 4) _buildStep4SecurityPin(isDark),
                      if (_step == 5) _buildStep5UsernameAndInterests(isDark),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0058FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _step == 5 ? 'Complete Registration' : 'Continue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: BUSINESS IDENTITY & AVATAR
  // ==========================================
  Widget _buildStep1BusinessInfo(bool isDark) {
    final activeAvatar = ref.watch(activeAvatarProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your animated companion avatar and provide your WhatsApp details.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // Avatar Picker Centerpiece
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  AvatarPickerSheet.show(context);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedCritterAvatar(
                      avatar: activeAvatar.currentAvatar,
                      size: 96,
                      showGlow: true,
                      isInteractive: false,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                activeAvatar.currentAvatar.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Tap avatar to choose character',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF0058FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        BizSquareTextField(
          label: 'Business / Store Name',
          hintText: 'e.g. Adebayo Electronics Ltd',
          controller: _businessNameController,
          prefixIcon: HugeIcons.strokeRoundedStore01,
        ),
        const SizedBox(height: 20),

        BizSquareTextField(
          label: 'WhatsApp Phone Number',
          hintText: '08012345678 or +234...',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: HugeIcons.strokeRoundedCall02,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: OFFERS DIFFERENTIATION (TWO-STEP COLLAPSIBLE ACCORDION)
  // ==========================================
  Widget _buildStep2OffersDifferentiation(bool isDark) {
    final theme = Theme.of(context);
    final categories = MicroNicheTaxonomy.categories;
    final primaryNiche = _primaryMicroNicheId != null
        ? MicroNicheTaxonomy.findMicroNicheById(_primaryMicroNicheId!)
        : null;

    final filteredCategories = _nicheSearchQuery.trim().isEmpty
        ? categories
        : categories.where((cat) {
            final catMatches = cat.name.toLowerCase().contains(_nicheSearchQuery.toLowerCase());
            final nicheMatches = cat.microNiches.any(
              (mn) => mn.name.toLowerCase().contains(_nicheSearchQuery.toLowerCase()),
            );
            return catMatches || nicheMatches;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you sell?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Specify your primary product focus, followed by any secondary lines.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // SECTION 1: PRIMARY OFFER (COLLAPSIBLE)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isSelectingPrimaryMode
                  ? const Color(0xFF0058FF)
                  : (isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
              width: _isSelectingPrimaryMode ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PRIMARY OFFER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Main Focus (1 of 1)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (!_isSelectingPrimaryMode && _primaryMicroNicheId != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isSelectingPrimaryMode = true);
                      },
                      child: Text(
                        'Change',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0058FF),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'What is the main thing you sell or deal on?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                primaryNiche != null
                    ? 'Selected: ${primaryNiche.name}'
                    : 'Choose your main trade category from the options below.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: primaryNiche != null
                      ? const Color(0xFF0058FF)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  fontWeight: primaryNiche != null ? FontWeight.w700 : FontWeight.w500,
                ),
              ),

              // If in primary selection mode, show option selection
              if (_isSelectingPrimaryMode) ...[
                const SizedBox(height: 16),
                _buildKeyboardNicheSelector(
                  categories: filteredCategories,
                  excludedIds: _secondaryMicroNicheIds,
                  selectedId: _primaryMicroNicheId,
                  onSelect: (id) {
                    setState(() {
                      _primaryMicroNicheId = id;
                      _isSelectingPrimaryMode = false;
                      _errorMessage = null;
                    });
                  },
                  isDark: isDark,
                  theme: theme,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // SECTION 2: SECONDARY OFFERS (EXPANDS WHEN PRIMARY IS SET)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !_isSelectingPrimaryMode
                  ? const Color(0xFF0058FF)
                  : (isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
              width: !_isSelectingPrimaryMode ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SECONDARY OFFERS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Optional (${_secondaryMicroNicheIds.length}/2)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Are there other things you sell?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSelectingPrimaryMode
                    ? 'Select your primary offering above to unlock secondary options.'
                    : 'Choose up to 2 additional product lines.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),

              if (!_isSelectingPrimaryMode) ...[
                const SizedBox(height: 16),
                _buildKeyboardNicheMultiSelector(
                  categories: filteredCategories,
                  excludedId: _primaryMicroNicheId,
                  selectedIds: _secondaryMicroNicheIds,
                  onToggle: (id) {
                    setState(() {
                      if (_secondaryMicroNicheIds.contains(id)) {
                        _secondaryMicroNicheIds.remove(id);
                      } else {
                        if (_secondaryMicroNicheIds.length < 2) {
                          _secondaryMicroNicheIds.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You can select up to 2 secondary offerings.')),
                          );
                        }
                      }
                    });
                  },
                  isDark: isDark,
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardNicheSelector({
    required List<dynamic> categories,
    required Set<String> excludedIds,
    required String? selectedId,
    required ValueChanged<String> onSelect,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        // Search Input
        BizSquareTextField(
          label: 'Filter Categories',
          hintText: 'Search micro-niches (e.g. Shoes, Laptops, Solar)...',
          prefixIcon: HugeIcons.strokeRoundedSearch01,
          onChanged: (val) => setState(() => _nicheSearchQuery = val),
        ),
        const SizedBox(height: 12),

        // Accordion of Key Tiles
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final availableNiches = (cat.microNiches as List)
                .where((mn) => !excludedIds.contains(mn.id))
                .toList();

            if (availableNiches.isEmpty) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key('primary_${cat.id}'),
                  initiallyExpanded: _expandedCategoryId == cat.id,
                  onExpansionChanged: (exp) {
                    setState(() => _expandedCategoryId = exp ? cat.id : null);
                  },
                  title: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableNiches.map((mn) {
                          final isSelected = selectedId == mn.id;
                          return _buildNicheKeyTile(
                            label: mn.name,
                            isSelected: isSelected,
                            onTap: () => onSelect(mn.id),
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyboardNicheMultiSelector({
    required List<dynamic> categories,
    required String? excludedId,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final cat = categories[i];
            // STRICT MUTUAL EXCLUSION: Omit the primary niche from secondary options
            final availableNiches = (cat.microNiches as List)
                .where((mn) => mn.id != excludedId)
                .toList();

            if (availableNiches.isEmpty) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key('secondary_${cat.id}'),
                  title: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableNiches.map((mn) {
                          final isSelected = selectedIds.contains(mn.id);
                          return _buildNicheKeyTile(
                            label: mn.name,
                            isSelected: isSelected,
                            onTap: () => onToggle(mn.id),
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNicheKeyTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0058FF)
              : (isDark ? const Color(0xFF161E2E) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0058FF)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0058FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: SETUP CODE (DEV B41230 SUPPORT)
  // ==========================================
  Widget _buildStep3SetupCode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Setup Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your invite passcode. For testing, you may use the developer code below.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // Dev Code Helper Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0058FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0058FF).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedFlash,
                    color: Color(0xFF0058FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Developer Passcode',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0058FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'In dev mode, use passcode B41230. In production, use your verified admin invite code.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _verificationCodeController.text = 'B41230';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap to Fill "B41230"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        BizSquareTextField(
          label: 'Setup Passcode',
          hintText: 'B41230',
          controller: _verificationCodeController,
          prefixIcon: HugeIcons.strokeRoundedKey01,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: SECURITY PIN SETUP
  // ==========================================
  Widget _buildStep4SecurityPin(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Security PIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set a 4-digit PIN to secure your business account.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 28),

        BizSquareTextField(
          label: '4-Digit PIN',
          hintText: '••••',
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: HugeIcons.strokeRoundedLockPassword,
        ),
        const SizedBox(height: 20),

        BizSquareTextField(
          label: 'Confirm 4-Digit PIN',
          hintText: '••••',
          controller: _pinConfirmController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: HugeIcons.strokeRoundedCheckmarkBadge01,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: USERNAME & INTERESTS (ANTI-ECHO-CHAMBER)
  // ==========================================
  Widget _buildStep5UsernameAndInterests(bool isDark) {
    final theme = Theme.of(context);
    final categories = MicroNicheTaxonomy.categories;
    final ownNiches = _allSelectedMicroNiches.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Handle & Interests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your unique @username and select products you want to discover.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        BizSquareTextField(
          label: 'Business Username',
          hintText: 'e.g. adebayo_stores',
          controller: _usernameController,
          onChanged: _onUsernameChanged,
          prefixIcon: HugeIcons.strokeRoundedUser,
          suffix: _isCheckingUsername
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0058FF)),
                  ),
                )
              : (_isUsernameAvailable == true
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    )
                  : (_isUsernameAvailable == false
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancelCircle,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        )
                      : null)),
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'What do you need / buy?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${_selectedInterestIds.length} / 5',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0058FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select up to 5 business interests to tune your weekly contact matches.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final availableNiches = (cat.microNiches as List)
                .where((mn) => !ownNiches.contains(mn.id))
                .toList();

            if (availableNiches.isEmpty) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key('interests_${cat.id}'),
                  title: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableNiches.map((mn) {
                          final isSelected = _selectedInterestIds.contains(mn.id);
                          return _buildNicheKeyTile(
                            label: mn.name,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedInterestIds.remove(mn.id);
                                } else {
                                  if (_selectedInterestIds.length < 5) {
                                    _selectedInterestIds.add(mn.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Maximum 5 interests allowed.')),
                                    );
                                  }
                                }
                              });
                            },
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
