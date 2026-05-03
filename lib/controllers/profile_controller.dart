import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class ProfileController {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Get user profile by ID
  Future<User?> getUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/user/$userId"));
      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user.toJson()));
        
        return user;
      }
      return null;
    } catch (e) {
      print("Get user profile error: $e");
      return null;
    }
  }

  /// Update user name
  Future<bool> updateName(String userId, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/update-name"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": userId, "full_name": fullName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update name error: $e");
      return false;
    }
  }

  /// Update user email
  Future<Map<String, dynamic>> updateEmail(String userId, String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/update-email"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": userId, "email": email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Update user password
  Future<Map<String, dynamic>> updatePassword(String userId, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/update-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": userId, "password": password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Upload avatar
  Future<bool> uploadAvatar(String userId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/user/upload-avatar"),
      );
      request.fields['id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Upload avatar error: $e");
      return false;
    }
  }

  /// Calculate level from XP
  int calculateLevel(int totalXp) {
    if (totalXp >= 2700) return 10;
    if (totalXp >= 2200) return 9;
    if (totalXp >= 1750) return 8;
    if (totalXp >= 1350) return 7;
    if (totalXp >= 1000) return 6;
    if (totalXp >= 700) return 5;
    if (totalXp >= 450) return 4;
    if (totalXp >= 250) return 3;
    if (totalXp >= 100) return 2;
    return 1;
  }

  /// Get XP target for next level
  int getXpTarget(int currentLevel) {
    const thresholds = [100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700];
    if (currentLevel >= 10) return 2700;
    return thresholds[currentLevel - 1];
  }
}
