import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

/// Handles the optional app-lock: a PIN (hashed, never stored in plain
/// text) with biometric unlock as a faster alternative when available.
class AuthLockService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  bool verifyPin(String pin, String storedHash) => hashPin(pin) == storedHash;

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Xác thực để mở khoá ứng dụng',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
