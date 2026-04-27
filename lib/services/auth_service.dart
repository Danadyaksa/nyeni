import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Gunakan 10.0.2.2 untuk emulator, atau IP laptopmu jika pakai HP fisik
  final String baseUrl = "http://10.0.2.2:3000/api";

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
  }
}