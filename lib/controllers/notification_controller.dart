import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotificationController {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Submit TPM feedback
  Future<Map<String, dynamic>> submitFeedback(String userId, String feedbackText) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/feedback"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "feedback_text": feedbackText,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Convert currency
  double convertCurrency(double amount, String from, String to) {
    // Exchange rates (IDR as base)
    const rates = {
      'IDR': 1.0,
      'USD': 0.000063,
      'EUR': 0.000058,
      'JPY': 0.0095,
    };

    if (!rates.containsKey(from) || !rates.containsKey(to)) {
      return amount;
    }

    // Convert to IDR first, then to target currency
    final inIDR = amount / rates[from]!;
    return inIDR * rates[to]!;
  }

  /// Convert time between timezones
  DateTime convertTime(DateTime time, String from, String to) {
    // Timezone offsets from UTC
    const offsets = {
      'WIB': 7,   // UTC+7
      'WITA': 8,  // UTC+8
      'WIT': 9,   // UTC+9
      'London': 0, // UTC+0
    };

    if (!offsets.containsKey(from) || !offsets.containsKey(to)) {
      return time;
    }

    // Convert to UTC first
    final utc = time.subtract(Duration(hours: offsets[from]!));
    // Then to target timezone
    return utc.add(Duration(hours: offsets[to]!));
  }
}
