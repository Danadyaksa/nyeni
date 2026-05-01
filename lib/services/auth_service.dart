import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Gunakan 10.0.2.2 untuk emulator, atau IP laptopmu jika pakai HP fisik
  static const String baseUrl = "http://192.168.18.85:3000/api";

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
