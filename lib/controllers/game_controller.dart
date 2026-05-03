import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GameController {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Update game progress (XP & level)
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
      print("Update progress error: $e");
      return false;
    }
  }

  /// Calculate new level from XP
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

  /// XP reward per game level
  static const int xpPerLevel = 100;
}
