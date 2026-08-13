import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/providers/auth_state_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/utils/phone_normalizer.dart';
import '../../core/widgets/bizsquare_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isAuthenticatingBiometrics = false;
  bool _hasLinkedAccount = false;
  bool _obscurePin = true;
  Map<String, dynamic>? _linkedAccount;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLinkedAccount();
  }

  Future<void> _checkLinkedAccount() async {
    final bioService = ref.read(biometricServiceProvider);
    final hasLinked = await bioService.hasLinkedAccount();
    if (hasLinked) {
      final account = await bioService.getLinkedAccount();
      if (mounted) {
        setState(() {
          _hasLinkedAccount = true;
          _linkedAccount = account;
          if (account?['phoneNumber'] != null && _phoneController.text.isEmpty) {
            _phoneController.text = account!['phoneNumber'] as String;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final rawPhone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (rawPhone.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number and 4-digit PIN.');
      return;
    }

    final normalizedPhone = PhoneNormalizer.normalize(rawPhone);
    if (normalizedPhone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid WhatsApp phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.login(phoneNumber: normalizedPhone, pin: pin);
      final token = result['token'] as String;
      api.setAuthToken(token);
      final user = result['user'] as Map<String, dynamic>;
      final supplyNiches = result['supplyNiches'] as List<dynamic>?;
      final baselineDemand = result['baselineDemand'] as List<dynamic>?;

      await ref.read(userStateProvider.notifier).login(
        token: token,
        user: user,
        supplyNiches: supplyNiches,
        baselineDemand: baselineDemand,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/daily-wall');
      }
    } on ApiException catch (e) {
      debugPrint('Login API error: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.statusCode == 401
              ? 'The phone number or PIN entered is incorrect. Please check and try again.'
              : 'Unable to sign in. Please verify your details and try again.';
        });
      }
    } catch (e) {
      debugPrint('Login unexpected error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to connect right now. Please check your internet connection.';
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    if (!_hasLinkedAccount || _linkedAccount == null || _isAuthenticatingBiometrics) return;

    setState(() => _isAuthenticatingBiometrics = true);
    HapticFeedback.lightImpact();

    final bioService = ref.read(biometricServiceProvider);
    final authenticated = await bioService.authenticate(
      reason: 'Scan fingerprint or Face ID to securely sign in to BizSquare',
    );

    if (!mounted) return;
    setState(() => _isAuthenticatingBiometrics = false);

    if (authenticated) {
      final token = _linkedAccount!['token'] as String;
      final user = _linkedAccount!['user'] as Map<String, dynamic>;

      await ref.read(userStateProvider.notifier).login(
        token: token,
        user: user,
      );

      if (mounted) {
        context.go('/daily-wall');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Text(
                'Welcome back',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to access your business community, weekly contact matches, and Spotlight.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 28),

              // Friendly Error Banner (if present)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Phone Field
              BizSquareTextField(
                label: 'Phone Number',
                hintText: 'e.g. 08012345678',
                controller: _phoneController,
                prefixIcon: HugeIcons.strokeRoundedCall02,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // PIN Field
              BizSquareTextField(
                label: '4-Digit Security PIN',
                hintText: '••••',
                controller: _pinController,
                prefixIcon: HugeIcons.strokeRoundedLockPassword,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffix: IconButton(
                  icon: HugeIcon(
                    icon: _obscurePin ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),

              const SizedBox(height: 28),

              // Primary Sign In Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),

              // Biometric Sign In Option (if enabled on device)
              if (_hasLinkedAccount) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isAuthenticatingBiometrics ? null : _handleBiometricAuth,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedShieldUser,
                    color: Color(0xFF0058FF),
                    size: 20,
                  ),
                  label: Text(
                    'Sign In with Biometrics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0058FF),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Color(0xFF0058FF), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Footer Register Prompt
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.pushReplacement('/register-steps');
                      },
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0058FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
