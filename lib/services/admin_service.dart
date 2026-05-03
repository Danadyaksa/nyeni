import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AdminService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ─── TICKETS ────────────────────────────────────────────────────────────────

  /// Ambil semua tiket PENDING untuk diverifikasi admin
  Future<List<dynamic>> getPendingTickets() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/tickets/pending"));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua tiket (semua status) untuk revenue & overview
  Future<List<dynamic>> getAllTickets() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/tickets"));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  /// Accept tiket → status jadi ACTIVE
  Future<bool> acceptTicket(String ticketId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/tickets/$ticketId/accept"),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Decline tiket → status jadi DECLINED
  Future<bool> declineTicket(String ticketId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/tickets/$ticketId/decline"),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Scan QR → tiket jadi EXPIRED
  Future<Map<String, dynamic>> scanTicket(String ticketId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/tickets/$ticketId/scan"),
        headers: {"Content-Type": "application/json"},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  // ─── EVENTS (CRUD) ───────────────────────────────────────────────────────────

  /// Ambil semua event (termasuk yang tidak aktif)
  Future<List<dynamic>> getAllEventsAdmin() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/events"));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  /// Tambah event baru
  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/admin/events"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Update event
  Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> eventData) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/events/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Hapus event
  Future<bool> deleteEvent(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/admin/events/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── REVENUE ─────────────────────────────────────────────────────────────────

  /// Ambil data revenue dari server
  Future<Map<String, dynamic>> getRevenue() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/revenue"));
      return response.statusCode == 200 ? jsonDecode(response.body) : {};
    } catch (e) {
      return {"error": "Koneksi server gagal: $e"};
    }
  }
}
