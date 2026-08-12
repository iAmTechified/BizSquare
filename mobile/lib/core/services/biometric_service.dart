import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final biometricsEnabledProvider = StateProvider<bool>((ref) => true);

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const _keyLinkedPhone = 'bizsquare_linked_phone';
  static const _keyLinkedToken = 'bizsquare_linked_jwt';
  static const _keyLinkedUserData = 'bizsquare_linked_user';
  static const _keyHasOnboarded = 'bizsquare_has_onboarded';

  /// Checks if physical biometric hardware is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns available biometric hardware types (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// Authenticates using OS biometric prompt (Fingerprint / Face ID)
  Future<bool> authenticate({
    String reason = 'Scan fingerprint or Face ID to securely sign in to BizSquare',
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // LINKED ACCOUNT PERSISTENCE & BIOMETRICS
  // ==========================================

  /// Checks if an authenticated account is linked to this physical device
  Future<bool> hasLinkedAccount() async {
    try {
      final token = await _storage.read(key: _keyLinkedToken);
      final phone = await _storage.read(key: _keyLinkedPhone);
      return token != null && token.isNotEmpty && phone != null && phone.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Gets stored linked account details
  Future<Map<String, dynamic>?> getLinkedAccount() async {
    try {
      final token = await _storage.read(key: _keyLinkedToken);
      final phone = await _storage.read(key: _keyLinkedPhone);
      final userJson = await _storage.read(key: _keyLinkedUserData);

      if (token == null || token.isEmpty || phone == null || phone.isEmpty) {
        return null;
      }

      Map<String, dynamic> user = {};
      if (userJson != null && userJson.isNotEmpty) {
        try {
          user = jsonDecode(userJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      return {
        'token': token,
        'phoneNumber': phone,
        'user': user,
      };
    } catch (_) {
      return null;
    }
  }

  /// Saves linked account credentials for biometrics & persistent session
  Future<void> saveLinkedAccount({
    required String token,
    required String phoneNumber,
    required Map<String, dynamic> user,
  }) async {
    try {
      await _storage.write(key: _keyLinkedToken, value: token);
      await _storage.write(key: _keyLinkedPhone, value: phoneNumber);
      await _storage.write(key: _keyLinkedUserData, value: jsonEncode(user));
      await _storage.write(key: _keyHasOnboarded, value: 'true');
    } catch (_) {}
  }

  /// Clears stored linked account on explicit logout/unlink
  Future<void> clearLinkedAccount() async {
    try {
      await _storage.delete(key: _keyLinkedToken);
      await _storage.delete(key: _keyLinkedPhone);
      await _storage.delete(key: _keyLinkedUserData);
    } catch (_) {}
  }

  /// Checks if onboarding was completed/seen
  Future<bool> hasCompletedOnboarding() async {
    try {
      final val = await _storage.read(key: _keyHasOnboarded);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Sets onboarding completion flag
  Future<void> setOnboardedFlag(bool completed) async {
    try {
      await _storage.write(key: _keyHasOnboarded, value: completed ? 'true' : 'false');
    } catch (_) {}
  }
}
