import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/recommendation_model.dart';
import '../config/api_config.dart';

class RecommendationController {
  static String get baseUrl => ApiConfig.baseUrl;

  // Get personalized recommendations for user
  Future<Recommendation?> getRecommendations(String userId) async {
    try {
      final url = "$baseUrl/recommendations/$userId";
      debugPrint('🌐 Calling API: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendation = Recommendation.fromJson(data);
        debugPrint('✅ Parsed recommendation: ${recommendation.events.length} events');
        return recommendation;
      } else {
        debugPrint('❌ API error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint("❌ Get recommendations error: $e");
      return null;
    }
  }
}
