import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_controller.dart';
import '../models/user_model.dart';

class BiometricController {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _authController = AuthController();

  // ==========================================
  // BIOMETRIC OPERATIONS
  // ==========================================

  /// Cek apakah device support biometric
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Cek apakah user sudah enable biometric (per user ID)
  Future<bool> isBiometricEnabled(String userId) async {
    final enabled = await _secureStorage.read(key: 'biometric_enabled_$userId');
    return enabled == 'true';
  }

  /// Enable biometric login
  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    await _secureStorage.write(key: 'biometric_enabled_$userId', value: enabled.toString());
  }

  /// Simpan credentials untuk biometric
  Future<void> saveBiometricCredentials(String userId, String email, String password) async {
    await _secureStorage.write(key: 'biometric_email_$userId', value: email);
    await _secureStorage.write(key: 'biometric_password_$userId', value: password);
  }

  /// Hapus credentials biometric
  Future<void> clearBiometricCredentials(String userId) async {
    await _secureStorage.delete(key: 'biometric_email_$userId');
    await _secureStorage.delete(key: 'biometric_password_$userId');
    await _secureStorage.delete(key: 'biometric_enabled_$userId');
  }

  /// Get last biometric user ID
  Future<String?> getLastBiometricUserId() async {
    return await _secureStorage.read(key: 'last_biometric_user_id');
  }

  /// Set last biometric user ID
  Future<void> setLastBiometricUserId(String userId) async {
    await _secureStorage.write(key: 'last_biometric_user_id', value: userId);
  }

  /// Login dengan biometric
  Future<User?> loginWithBiometric() async {
    try {
      // Get last biometric user
      final userId = await getLastBiometricUserId();
      if (userId == null) {
        print("No biometric user found");
        return null;
      }

      // Check if enabled
      final enabled = await isBiometricEnabled(userId);
      if (!enabled) {
        print("Biometric not enabled for user $userId");
        return null;
      }

      // Authenticate
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan biometric untuk masuk ke Nyeni',
      );

      if (!authenticated) {
        print("Biometric authentication failed");
        return null;
      }

      // Get credentials
      final email = await _secureStorage.read(key: 'biometric_email_$userId');
      final password = await _secureStorage.read(key: 'biometric_password_$userId');

      if (email == null || password == null) {
        print("Credentials not found");
        return null;
      }

      // Login
      return await _authController.login(email, password);
    } catch (e) {
      print("Biometric login error: $e");
      return null;
    }
  }
}
