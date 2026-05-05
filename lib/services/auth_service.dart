import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/api_config.dart';

class AuthService {
  // Gunakan ApiConfig untuk base URL
  static String get baseUrl => ApiConfig.baseUrl;
  
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  // Cek apakah device support biometric
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Cek apakah user sudah enable biometric login (per user ID)
  Future<bool> isBiometricEnabled(String userId) async {
    final enabled = await _secureStorage.read(key: 'biometric_enabled_$userId');
    return enabled == 'true';
  }

  /// Enable/disable biometric login (per user ID)
  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    await _secureStorage.write(key: 'biometric_enabled_$userId', value: enabled.toString());
  }

  /// Simpan credentials untuk biometric login (per user ID)
  Future<void> saveBiometricCredentials(String userId, String email, String password) async {
    await _secureStorage.write(key: 'biometric_email_$userId', value: email);
    await _secureStorage.write(key: 'biometric_password_$userId', value: password);
  }

  /// Hapus credentials biometric (per user ID)
  Future<void> clearBiometricCredentials(String userId) async {
    await _secureStorage.delete(key: 'biometric_email_$userId');
    await _secureStorage.delete(key: 'biometric_password_$userId');
    await _secureStorage.delete(key: 'biometric_enabled_$userId');
  }

  /// Cek apakah ada user yang pernah enable biometric (untuk login screen)
  Future<String?> getLastBiometricUserId() async {
    return await _secureStorage.read(key: 'last_biometric_user_id');
  }

  /// Simpan user ID terakhir yang enable biometric
  Future<void> setLastBiometricUserId(String userId) async {
    await _secureStorage.write(key: 'last_biometric_user_id', value: userId);
  }

  /// Authenticate dengan biometric dan login otomatis
  Future<Map<String, dynamic>> loginWithBiometric() async {
    try {
      // Ambil user ID terakhir yang enable biometric
      final userId = await getLastBiometricUserId();
      if (userId == null) {
        return {"error": "Biometric login belum diaktifkan"};
      }

      // Cek apakah user ini sudah enable biometric
      final enabled = await isBiometricEnabled(userId);
      if (!enabled) {
        return {"error": "Biometric login belum diaktifkan"};
      }

      // Authenticate dengan biometric
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan biometric untuk masuk ke Nyeni',
      );

      if (!authenticated) {
        return {"error": "Autentikasi biometric gagal"};
      }

      // Ambil credentials dari secure storage
      final email = await _secureStorage.read(key: 'biometric_email_$userId');
      final password = await _secureStorage.read(key: 'biometric_password_$userId');

      if (email == null || password == null) {
        return {"error": "Credentials tidak ditemukan. Silakan login manual terlebih dahulu."};
      }

      // Login dengan credentials tersimpan
      return await login(email, password);
    } catch (e) {
      return {"error": "Biometric authentication error: $e"};
    }
  }

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
      }
      return data;
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  // VERIFY PASSWORD (tanpa update session, untuk enable biometric)
  Future<Map<String, dynamic>> verifyPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  // REGISTER
  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password, "full_name": fullName}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  Future<Map<String, dynamic>> buyTicket(
    String userId,
    String eventName,
    String eventDate, {
    int uniqueCode = 0,
    int serviceFee = 2500,
    int ticketPrice = 0,
    int totalAmount = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tickets/checkout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "event_name": eventName,
          "event_date": eventDate,
          "unique_code": uniqueCode,
          "service_fee": serviceFee,
          "ticket_price": ticketPrice,
          "total_amount": totalAmount,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Buat N tiket sekaligus — masing-masing dapat UUID & QR unik sendiri.
  /// Biaya layanan (service_fee) flat per transaksi, bukan per tiket.
  Future<Map<String, dynamic>> buyTickets({
    required String userId,
    required String eventName,
    required String eventDate,
    required int count,
    int uniqueCode = 0,
    int serviceFee = 2500,
    int ticketPrice = 0,
    int totalAmount = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tickets/checkout-bulk"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "event_name": eventName,
          "event_date": eventDate,
          "count": count,
          "unique_code": uniqueCode,
          "service_fee": serviceFee,   // flat per transaksi
          "ticket_price": ticketPrice, // harga per tiket
          "total_amount": totalAmount, // total keseluruhan
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  // UPDATE PROGRESS (Untuk Game Trivia & Labirin)
  Future<bool> updateProgress({
    required String userId,
    required int totalXp,
    required int level,
    required int triviaLevel,
    required int labirinLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/update-progress"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": userId,
          "total_xp": totalXp,
          "level": level,
          "completed_levels_trivia": triviaLevel,
          "completed_levels_labirin": labirinLevel,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Clear notifications from Hive
    try {
      if (Hive.isBoxOpen('notifications')) {
        final box = Hive.box('notifications');
        await box.clear();
      }
    } catch (e) {
      debugPrint('Error clearing notifications on logout: $e');
    }
  }

  Future<List<dynamic>> getMyTickets(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tickets/my-tickets/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error narik tiket: $e");
      return [];
    }
  }

  Future<List<dynamic>> getAllEvents() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/events"));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  // Narik 1 event buat di halaman detail
  Future<Map<String, dynamic>?> getEventDetail(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/events/$id"));
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }
}
