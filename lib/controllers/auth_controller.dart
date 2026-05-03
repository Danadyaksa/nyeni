import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthController {
  // Gunakan ApiConfig untuk base URL
  static String get baseUrl => ApiConfig.baseUrl;

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  /// Login user dengan email & password
  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_data', jsonEncode(data['user']));
        
        // Return user model
        return User.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  /// Register user baru
  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "full_name": fullName,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Verify password (untuk enable biometric)
  Future<bool> verifyPassword(String email, String password) async {
    try {
      print('🌐 AuthController: Calling verify-password API...');
      print('🌐 AuthController: URL: $baseUrl/auth/verify-password');
      print('🌐 AuthController: Email: $email');
      
      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🌐 AuthController: Request timeout!');
          throw Exception('Request timeout');
        },
      );

      print('🌐 AuthController: Response status: ${response.statusCode}');
      print('🌐 AuthController: Response body: ${response.body}');

      final data = jsonDecode(response.body);
      final verified = data['verified'] == true;
      
      print('🌐 AuthController: Verified: $verified');
      return verified;
    } catch (e) {
      print("🌐 AuthController: Verify password error: $e");
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get current logged in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_data');
      if (userString != null) {
        return User.fromJson(jsonDecode(userString));
      }
      return null;
    } catch (e) {
      print("Get current user error: $e");
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  /// Get user token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
