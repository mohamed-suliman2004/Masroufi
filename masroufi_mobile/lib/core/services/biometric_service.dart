import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricsPrefKey = 'masroufi_biometrics_enabled';

  /// Check if the device hardware supports biometrics and has registered fingerprints/faces
  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  /// Check if biometrics is enabled in user preferences
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsPrefKey) ?? true;
  }

  /// Save biometrics toggle preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsPrefKey, enabled);
  }

  /// Trigger native Biometric Prompt (Fingerprint / Face / Device PIN fallback)
  static Future<bool> authenticate({
    String reason = 'يرجى تأكيد هويتك عبر البصمة للمتابعة في مصروفي',
  }) async {
    if (kIsWeb) return true;

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      return authenticated;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
