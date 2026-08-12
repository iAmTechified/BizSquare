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
import '../../core/widgets/bizsquare_loader.dart';
import '../../core/widgets/bizsquare_text_field.dart';
import '../../core/services/avatar_service.dart';

class MultiStepRegisterScreen extends ConsumerStatefulWidget {
  const MultiStepRegisterScreen({super.key});

  @override
  ConsumerState<MultiStepRegisterScreen> createState() => _MultiStepRegisterScreenState();
}

class _MultiStepRegisterScreenState extends ConsumerState<MultiStepRegisterScreen> {
  int _step = 1; // 1: Profile, 2: Mainly Sell, 3: Other Sell, 4: Passcode, 5: PIN, 6: Username & Interests
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 Controllers
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 & 3 Micro-Niche State
  String? _primaryMicroNicheId;
  final Set<String> _secondaryMicroNicheIds = {};
  String _nicheSearchQuery = '';
  String? _expandedCategoryId;

  // Step 4 Verification Code Controller
  final _verificationCodeController = TextEditingController();

  // Step 5 Security PIN Controller
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();

  // Step 6 Username & Interests
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
    _step = draft.currentStep > 6 ? 6 : draft.currentStep;
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
      // Step 2: "What do you sell mainly?"
      if (_primaryMicroNicheId == null) {
        setState(() => _errorMessage = 'Please select the main product line you sell.');
        return;
      }

      await ref.read(onboardingDraftProvider.notifier).updateStep2(
        microNicheIds: [_primaryMicroNicheId!],
        primaryMicroNicheId: _primaryMicroNicheId!,
      );

      setState(() => _step = 3);
    } else if (_step == 3) {
      // Step 3: "Do you sell any other things?"
      final allNiches = _allSelectedMicroNiches;
      await ref.read(onboardingDraftProvider.notifier).updateStep2(
        microNicheIds: allNiches,
        primaryMicroNicheId: _primaryMicroNicheId!,
      );

      setState(() => _step = 4);
    } else if (_step == 4) {
      // Step 4: Verification Code
      final code = _verificationCodeController.text.trim().toUpperCase();
      if (code.isEmpty || code.length < 4) {
        setState(() => _errorMessage = 'Please enter your passcode.');
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
          _step = 5;
        });
      } on ApiException catch (e) {
        debugPrint('Register verify error: ${e.message}');
        setState(() {
          _isLoading = false;
          if (e.code == 'INVALID_CODE') {
            _errorMessage = 'Invalid Passcode. Please verify your code and try again.';
          } else if (e.code == 'CODE_ALREADY_USED') {
            _errorMessage = 'This passcode has already been claimed.';
          } else if (e.code == 'CODE_EXPIRED') {
            _errorMessage = 'This passcode has expired.';
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
    } else if (_step == 5) {
      // Step 5: Security PIN
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
      setState(() => _step = 6);
    } else if (_step == 6) {
      // Step 6: Username & Interests
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
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network timeout. Please tap finish to retry.';
        });
      }
    }
  }

  void _handleSkipSecondary() {
    setState(() => _errorMessage = null);
    HapticFeedback.lightImpact();
    _secondaryMicroNicheIds.clear();
    setState(() => _step = 4);
  }

  void _handleBack() {
    setState(() => _errorMessage = null);
    if (_step > 1) {
      setState(() => _step--);
    } else {
      context.go('/auth-wall');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.indigo),
          onPressed: _handleBack,
        ),
        title: Text(
          'Step $_step of 6',
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
            // Top Progress Indicator
            LinearProgressIndicator(
              value: _step / 6,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0058FF)),
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (_step == 2) _buildStep2WhatDoYouSellMainly(isDark),
                    if (_step == 3) _buildStep3DoYouSellAnyOtherThings(isDark),
                    if (_step == 4) _buildStep4SetupCode(isDark),
                    if (_step == 5) _buildStep5SecurityPin(isDark),
                    if (_step == 6) _buildStep6UsernameAndInterests(isDark),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom CTAs
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_step == 3) ...[
                    // Obvious "No, Continue" Secondary Action
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _handleSkipSecondary,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'No, Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
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
                          ? const BizSquareLoader(size: 24)
                          : Text(
                              _step == 6 ? 'Complete Registration' : 'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          'Create Your Business Identity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick your business avatar and enter your WhatsApp contact details.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // Animated Critter Avatar Picker Trigger
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
  // STEP 2: "WHAT DO YOU SELL MAINLY?"
  // ==========================================
  Widget _buildStep2WhatDoYouSellMainly(bool isDark) {
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
          'What do you sell mainly?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the single main product line your business supplies. This forms your core network identity.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Selected Primary Niche Chip Display
        if (primaryNiche != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0058FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0058FF), width: 1.5),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                  color: Color(0xFF0058FF),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAIN PRIMARY PRODUCT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0058FF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        primaryNiche.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Search Field
        BizSquareTextField(
          label: 'Search Product Lines',
          hintText: 'e.g. Phones, Solar, Fabrics...',
          prefixIcon: HugeIcons.strokeRoundedSearch01,
          onChanged: (val) => setState(() => _nicheSearchQuery = val),
        ),
        const SizedBox(height: 16),

        // Category Expandable Accordion List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredCategories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final cat = filteredCategories[idx];
            final isExpanded = _expandedCategoryId == cat.id || _nicheSearchQuery.isNotEmpty;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key(cat.id),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (exp) {
                    if (exp) setState(() => _expandedCategoryId = cat.id);
                  },
                  title: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cat.microNiches.map((mn) {
                        final isPrimary = _primaryMicroNicheId == mn.id;

                        return ChoiceChip(
                          selected: isPrimary,
                          showCheckmark: false,
                          label: Text(mn.name),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                            color: isPrimary
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                          ),
                          selectedColor: const Color(0xFF0058FF),
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          onSelected: (sel) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (sel) {
                                _primaryMicroNicheId = mn.id;
                                _secondaryMicroNicheIds.remove(mn.id);
                              }
                            });
                          },
                        );
                      }).toList(),
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

  // ==========================================
  // STEP 3: "DO YOU SELL ANY OTHER THINGS?"
  // ==========================================
  Widget _buildStep3DoYouSellAnyOtherThings(bool isDark) {
    final categories = MicroNicheTaxonomy.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you sell any other things?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select up to 2 secondary product lines you supply. Your main product is already saved.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Search Field
        BizSquareTextField(
          label: 'Search Secondary Lines',
          hintText: 'e.g. Accessories, Repairs, Spare Parts...',
          prefixIcon: HugeIcons.strokeRoundedSearch01,
          onChanged: (val) => setState(() => _nicheSearchQuery = val),
        ),
        const SizedBox(height: 16),

        // Category Accordion List for Secondary
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final cat = categories[idx];

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: idx == 0 || _nicheSearchQuery.isNotEmpty,
                title: Text(
                  cat.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cat.microNiches.map((mn) {
                      final isPrimary = _primaryMicroNicheId == mn.id;
                      final isSecondary = _secondaryMicroNicheIds.contains(mn.id);

                      if (isPrimary) {
                        return Chip(
                          label: Text('${mn.name} (Main)'),
                          backgroundColor: const Color(0xFF0058FF).withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0058FF),
                          ),
                        );
                      }

                      return FilterChip(
                        selected: isSecondary,
                        showCheckmark: false,
                        label: Text(mn.name),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSecondary ? FontWeight.w700 : FontWeight.w500,
                          color: isSecondary
                              ? Colors.white
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                        ),
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        onSelected: (sel) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (sel) {
                              if (_secondaryMicroNicheIds.length >= 2) {
                                _errorMessage = 'You can select up to 2 secondary products.';
                                return;
                              }
                              _secondaryMicroNicheIds.add(mn.id);
                            } else {
                              _secondaryMicroNicheIds.remove(mn.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: SETUP CODE (DEV B41230 SUPPORTED SILENTLY)
  // ==========================================
  Widget _buildStep4SetupCode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Passcode',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the verification passcode sent to your WhatsApp number.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        BizSquareTextField(
          label: 'Passcode',
          hintText: 'e.g. B41230',
          controller: _verificationCodeController,
          prefixIcon: HugeIcons.strokeRoundedCheckmarkBadge01,
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: SECURITY PIN CREATION
  // ==========================================
  Widget _buildStep5SecurityPin(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create 4-Digit PIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a 4-digit PIN to secure your account for instant sign in.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        BizSquareTextField(
          label: '4-Digit PIN',
          hintText: '••••',
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          prefixIcon: HugeIcons.strokeRoundedLockKey,
        ),
        const SizedBox(height: 20),

        BizSquareTextField(
          label: 'Confirm PIN',
          hintText: '••••',
          controller: _pinConfirmController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          prefixIcon: HugeIcons.strokeRoundedLockKey,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 6: USERNAME & INTERESTS
  // ==========================================
  Widget _buildStep6UsernameAndInterests(bool isDark) {
    final categories = MicroNicheTaxonomy.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Claim Username & Interests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your @handle and select what products you want to buy or source.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        BizSquareTextField(
          label: 'Username (@handle)',
          hintText: 'e.g. adebayo_store',
          controller: _usernameController,
          prefixIcon: HugeIcons.strokeRoundedAt,
          onChanged: _onUsernameChanged,
        ),

        if (_isCheckingUsername) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
              const SizedBox(width: 8),
              Text(
                'Checking username availability...',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ] else if (_isUsernameAvailable != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isUsernameAvailable! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: _isUsernameAvailable! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isUsernameAvailable! ? 'Username is available!' : 'Username is taken.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isUsernameAvailable! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 28),

        Text(
          'Products You Want to Buy / Source',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select categories to receive weekly matched suppliers.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final cat = categories[idx];

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: idx == 0,
                title: Text(
                  cat.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cat.microNiches.map((mn) {
                      final isSelected = _selectedInterestIds.contains(mn.id);
                      final isOwnPrimary = _primaryMicroNicheId == mn.id;

                      if (isOwnPrimary) {
                        return Tooltip(
                          message: 'Cannot select your own primary supply product as a buy interest',
                          child: Chip(
                            label: Text('${mn.name} (Your Product)'),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      }

                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Text(mn.name),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                        ),
                        selectedColor: const Color(0xFF0058FF),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        onSelected: (sel) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (sel) {
                              _selectedInterestIds.add(mn.id);
                            } else {
                              _selectedInterestIds.remove(mn.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
