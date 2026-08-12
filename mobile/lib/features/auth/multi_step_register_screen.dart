import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/micro_niche_taxonomy.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../core/widgets/animated_critter_avatar.dart';
import '../../core/widgets/avatar_picker_sheet.dart';
import '../../core/widgets/bizsquare_loader.dart';
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

  // Step 2 Micro-Niche State (Primary vs Secondary Differentiation)
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

  // Combined active supply micro-niches
  List<String> get _allSelectedMicroNiches {
    final list = <String>[];
    if (_primaryMicroNicheId != null) list.add(_primaryMicroNicheId!);
    list.addAll(_secondaryMicroNicheIds);
    return list;
  }

  // ==========================================
  // NAVIGATION & STEP VALIDATION
  // ==========================================
  Future<void> _handleNext() async {
    setState(() => _errorMessage = null);

    if (_step == 1) {
      final bName = _businessNameController.text.trim();
      final phone = _phoneController.text.trim();
      if (bName.isEmpty) {
        setState(() => _errorMessage = 'Please enter your Business / Store Name');
        return;
      }
      final normalized = PhoneNormalizer.normalize(phone);
      if (normalized.isEmpty) {
        setState(() => _errorMessage = 'Please enter a valid Phone Number');
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
        setState(() => _errorMessage = 'Please select your Primary Offer (What you mainly sell)');
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
        setState(() => _errorMessage = 'Please enter your Passcode (Use B41230 in dev mode)');
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
        setState(() {
          _isLoading = false;
          if (e.code == 'INVALID_CODE') {
            _errorMessage = 'Invalid Passcode. Use B41230 for dev testing.';
          } else if (e.code == 'CODE_ALREADY_USED') {
            _errorMessage = 'This Passcode has already been claimed by another user.';
          } else if (e.code == 'CODE_EXPIRED') {
            _errorMessage = 'This Passcode has expired. Use B41230 for dev testing.';
          } else if (e.code == 'PHONE_ALREADY_REGISTERED') {
            _errorMessage = 'This phone number is already registered. Please log in instead.';
          } else {
            _errorMessage = e.message;
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error. Please check your network and try again.';
        });
      }
    } else if (_step == 4) {
      final pin = _pinController.text.trim();
      final pinConfirm = _pinConfirmController.text.trim();

      if (pin.length != 4) {
        setState(() => _errorMessage = 'PIN must be exactly 4 digits');
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
        setState(() => _errorMessage = 'Username must be at least 3 characters');
        return;
      }
      if (_isUsernameAvailable == false) {
        setState(() => _errorMessage = 'Username is not available');
        return;
      }
      if (_selectedInterestIds.isEmpty) {
        setState(() => _errorMessage = 'Please select at least 1 interest to tune your matching signals');
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
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to complete registration. Please try again.';
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
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: _handleBack,
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
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _step / 5.0,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0058FF)),
                    minHeight: 4,
                  ),
                ),
              ),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0055).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFF0055).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF0055), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFFFF0055),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_step == 1) _buildStep1BusinessInfo(isDark),
                      if (_step == 2) _buildStep2OffersDifferentiation(isDark),
                      if (_step == 3) _buildStep3SetupCode(isDark),
                      if (_step == 4) _buildStep4SecurityPin(isDark),
                      if (_step == 5) _buildStep5UsernameAndInterests(isDark),
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
                        ? const BizSquareLoader(size: 20)
                        : Text(
                            _step == 5 ? 'Enter the Square ✨' : 'Continue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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
          style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick your business avatar and tell other verified sellers who you are.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 28),

        // Avatar Picker Centerpiece
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => AvatarPickerSheet.show(context),
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
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                activeAvatar.currentAvatar.name,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                'Tap to switch avatar',
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

        TextField(
          controller: _businessNameController,
          decoration: InputDecoration(
            labelText: 'Business / Store Name',
            hintText: 'e.g. Adebayo Electronics Ltd',
            prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number (WhatsApp)',
            hintText: '0801 234 5678 or +234...',
            prefixIcon: const Icon(Icons.phone_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: OFFERS DIFFERENTIATION (PRIMARY VS SECONDARY)
  // ==========================================
  Widget _buildStep2OffersDifferentiation(bool isDark) {
    final theme = Theme.of(context);
    final categories = MicroNicheTaxonomy.categories;
    final primaryNiche = _primaryMicroNicheId != null ? MicroNicheTaxonomy.findMicroNicheById(_primaryMicroNicheId!) : null;

    final filteredCategories = _nicheSearchQuery.trim().isEmpty
        ? categories
        : categories.where((cat) {
            final catMatches = cat.name.toLowerCase().contains(_nicheSearchQuery.toLowerCase());
            final nicheMatches = cat.microNiches.any((mn) => mn.name.toLowerCase().contains(_nicheSearchQuery.toLowerCase()));
            return catMatches || nicheMatches;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you sell?',
          style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Differentiate your main offering from any secondary items you sell.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),

        // SECTION 1: PRIMARY OFFER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _primaryMicroNicheId != null ? const Color(0xFF0058FF) : (isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
              width: _primaryMicroNicheId != null ? 1.8 : 1.2,
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                        'Main Focus',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (_primaryMicroNicheId != null)
                    GestureDetector(
                      onTap: () => setState(() => _isSelectingPrimaryMode = true),
                      child: Text(
                        'Change',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0058FF),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'What do you mainly sell or deal on?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                primaryNiche != null
                    ? 'Selected: ${primaryNiche.name}'
                    : 'Tap below to select your primary micro-niche from the taxonomy.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: primaryNiche != null ? const Color(0xFF0058FF) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  fontWeight: primaryNiche != null ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // SECTION 2: SECONDARY OFFERS (OPTIONAL)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
              width: 1.2,
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                ),
              ),
              const SizedBox(height: 8),

              if (_secondaryMicroNicheIds.isEmpty)
                Text(
                  'No secondary offerings selected (optional).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _secondaryMicroNicheIds.map((id) {
                    final niche = MicroNicheTaxonomy.findMicroNicheById(id);
                    return Chip(
                      label: Text(
                        niche?.name ?? id,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () {
                        setState(() => _secondaryMicroNicheIds.remove(id));
                      },
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Search Bar
        TextField(
          onChanged: (val) => setState(() => _nicheSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search micro-niches (e.g. Footwear, Gadgets, Catering)...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: isDark ? const Color(0xFF161E2E) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 16),

        // Category Accordion List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredCategories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final cat = filteredCategories[i];
            final isExpanded = _expandedCategoryId == cat.id;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key(cat.id),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (exp) {
                    setState(() => _expandedCategoryId = exp ? cat.id : null);
                  },
                  title: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cat.microNiches.map((mn) {
                          final isPrimary = _primaryMicroNicheId == mn.id;
                          final isSecondary = _secondaryMicroNicheIds.contains(mn.id);

                          return FilterChip(
                            label: Text(mn.name),
                            selected: isPrimary || isSecondary,
                            onSelected: (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (selected) {
                                  if (_primaryMicroNicheId == null || _isSelectingPrimaryMode) {
                                    // Remove from secondary if was there
                                    _secondaryMicroNicheIds.remove(mn.id);
                                    _primaryMicroNicheId = mn.id;
                                    _isSelectingPrimaryMode = false;
                                  } else if (_secondaryMicroNicheIds.length < 2) {
                                    _secondaryMicroNicheIds.add(mn.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Maximum 2 secondary offerings allowed')),
                                    );
                                  }
                                } else {
                                  if (isPrimary) {
                                    _primaryMicroNicheId = null;
                                    _isSelectingPrimaryMode = true;
                                  } else {
                                    _secondaryMicroNicheIds.remove(mn.id);
                                  }
                                }
                              });
                            },
                            selectedColor: isPrimary ? const Color(0xFF0058FF) : const Color(0xFF10B981),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: (isPrimary || isSecondary) ? FontWeight.w700 : FontWeight.w500,
                              color: (isPrimary || isSecondary) ? Colors.white : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide.none,
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

  // ==========================================
  // STEP 3: SETUP CODE (DEV B41230 SUPPORT)
  // ==========================================
  Widget _buildStep3SetupCode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Setup Code',
          style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the setup code provided by the administrator or use B41230 in dev mode.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                  const Icon(Icons.developer_mode_rounded, color: Color(0xFF0058FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Developer / Test Passcode',
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
                'In dev mode, use code B41230. In production, use your assigned admin invite code.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
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
                    '⚡ Tap to Fill "B41230"',
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

        TextField(
          controller: _verificationCodeController,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 6),
          decoration: InputDecoration(
            labelText: 'Setup Passcode',
            hintText: 'B41230',
            prefixIcon: const Icon(Icons.key_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Your 4-digit PIN is used to sign in to your account and authorize updates.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 28),

        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '4-Digit PIN',
            counterText: '',
            prefixIcon: const Icon(Icons.lock_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _pinConfirmController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Confirm 4-Digit PIN',
            counterText: '',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your unique @username and select products/services you want to discover.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _usernameController,
          onChanged: _onUsernameChanged,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'e.g. adebayo_stores',
            prefixText: '@',
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
            suffixIcon: _isCheckingUsername
                ? const SizedBox(width: 20, height: 20, child: Center(child: BizSquareLoader(size: 16)))
                : (_isUsernameAvailable == true
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                    : (_isUsernameAvailable == false
                        ? const Icon(Icons.cancel_rounded, color: Color(0xFFFF0055), size: 20)
                        : null)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'What do you need/buy?',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_selectedInterestIds.length} / 5',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0058FF)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select up to 5 business interests (your own supply is excluded to prevent echo chambers).',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final availableNiches = cat.microNiches.where((mn) => !ownNiches.contains(mn.id)).toList();
            if (availableNiches.isEmpty) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableNiches.map((mn) {
                          final isSelected = _selectedInterestIds.contains(mn.id);
                          return FilterChip(
                            label: Text(mn.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (selected) {
                                  if (_selectedInterestIds.length < 5) {
                                    _selectedInterestIds.add(mn.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Maximum 5 interests allowed')),
                                    );
                                  }
                                } else {
                                  _selectedInterestIds.remove(mn.id);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF0058FF),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide.none,
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
