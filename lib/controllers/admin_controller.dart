import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../models/feedback_model.dart';
import '../config/api_config.dart';

class AdminController {
  // Gunakan ApiConfig untuk base URL
  static String get baseUrl => ApiConfig.baseUrl;

  // Create new event
  Future<Map<String, dynamic>> createEvent({
    required String name,
    required String category,
    required String description,
    required String date,
    required String location,
    double? latitude,
    double? longitude,
    required int price,
    String? imageUrl,
    bool? isActive,
    String? eventStartDate,
    String? eventEndDate,
    String? openTime,
    String? closeTime,
    String? regularStart,
    String? regularEnd,
    int? earlyBirdPrice,
    String? earlyBirdStart,
    String? earlyBirdEnd,
  }) async {
    try {
      final body = {
        "title": name,
        "category": category,
        "description": description,
        "event_date": date,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "price": price,
        "image_url": imageUrl,
        "is_active": isActive ?? true, // Default true jika tidak di-set
        "event_start_date": eventStartDate,
        "event_end_date": eventEndDate,
        "open_time": openTime,
        "close_time": closeTime,
        "regular_start": regularStart,
        "regular_end": regularEnd,
        "early_bird_price": earlyBirdPrice,
        "early_bird_start": earlyBirdStart,
        "early_bird_end": earlyBirdEnd,
      };
      
      print('🔵 AdminController.createEvent - Sending to backend: $body');
      
      final response = await http.post(
        Uri.parse("$baseUrl/admin/events"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      
      print('🔵 AdminController.createEvent - Response status: ${response.statusCode}');
      print('🔵 AdminController.createEvent - Response body: ${response.body}');
      
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 AdminController.createEvent - Error: $e');
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Update event
  Future<Map<String, dynamic>> updateEvent({
    required int id,
    required String name,
    required String category,
    required String description,
    required String date,
    required String location,
    double? latitude,
    double? longitude,
    required int price,
    String? imageUrl,
    bool? isActive,
    String? eventStartDate,
    String? eventEndDate,
    String? openTime,
    String? closeTime,
    String? regularStart,
    String? regularEnd,
    int? earlyBirdPrice,
    String? earlyBirdStart,
    String? earlyBirdEnd,
  }) async {
    try {
      final body = {
        "title": name,
        "category": category,
        "description": description,
        "event_date": date,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "price": price,
        "image_url": imageUrl,
        "is_active": isActive ?? true,
        "event_start_date": eventStartDate,
        "event_end_date": eventEndDate,
        "open_time": openTime,
        "close_time": closeTime,
        "regular_start": regularStart,
        "regular_end": regularEnd,
        "early_bird_price": earlyBirdPrice,
        "early_bird_start": earlyBirdStart,
        "early_bird_end": earlyBirdEnd,
      };
      
      print('🔵 Updating event $id with data: $body');
      
      final response = await http.put(
        Uri.parse("$baseUrl/admin/events/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      
      print('🔵 Update response status: ${response.statusCode}');
      print('🔵 Update response body: ${response.body}');
      
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Error updating event: $e');
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Delete event
  Future<Map<String, dynamic>> deleteEvent(int id) async {
    try {
      print('🔵 Deleting event: $id');
      final response = await http.delete(Uri.parse("$baseUrl/admin/events/$id"));
      print('🔵 Delete response status: ${response.statusCode}');
      print('🔵 Delete response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message'] ?? "Event berhasil dihapus!"};
      } else {
        // Parse error message dari server
        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false, 
            "error": errorData['error'] ?? "Gagal menghapus event",
            "suggestion": errorData['suggestion']
          };
        } catch (_) {
          return {"success": false, "error": "Server error: ${response.statusCode}"};
        }
      }
    } catch (e) {
      print("🔴 Delete event error: $e");
      return {"success": false, "error": "Koneksi server gagal: $e"};
    }
  }

  /// Upload event image
  Future<String?> uploadEventImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/admin/events/upload-image"),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        return data['image_url'];
      }
      return null;
    } catch (e) {
      print("Upload image error: $e");
      return null;
    }
  }

  // Get all tickets
  Future<List<Ticket>> getAllTickets() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/tickets"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Ticket.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Get tickets error: $e");
      return [];
    }
  }

  /// Accept ticket (activate + give XP)
  Future<Map<String, dynamic>> acceptTicket(String ticketId) async {
    try {
      print('🔵 Accepting ticket: $ticketId');
      final response = await http.put(
        Uri.parse("$baseUrl/admin/tickets/$ticketId/accept"),
      );
      print('🔵 Accept response status: ${response.statusCode}');
      print('🔵 Accept response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Server error: ${response.statusCode} - ${response.body}"};
      }
    } catch (e) {
      print('🔴 Error accepting ticket: $e');
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Decline ticket
  Future<Map<String, dynamic>> declineTicket(String ticketId) async {
    try {
      print('🔵 Declining ticket: $ticketId');
      final response = await http.put(
        Uri.parse("$baseUrl/admin/tickets/$ticketId/decline"),
      );
      print('🔵 Decline response status: ${response.statusCode}');
      print('🔵 Decline response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Server error: ${response.statusCode} - ${response.body}"};
      }
    } catch (e) {
      print('🔴 Error declining ticket: $e');
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  // Get all feedbacks
  Future<List<Feedback>> getAllFeedbacks() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/feedbacks"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Feedback.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Get feedbacks error: $e");
      return [];
    }
  }

  // Get revenue statistics
  Future<Map<String, dynamic>> getRevenue() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/revenue"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("Get revenue error: $e");
      return {};
    }
  }

  /// Get all events (admin)
  Future<List<dynamic>> getAllEventsAdmin() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/events"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Get events error: $e");
      return [];
    }
  }

  /// Scan ticket (QR code validation)
  Future<Map<String, dynamic>> scanTicket(String ticketId) async {
    try {
      print('🔵 Scanning ticket: $ticketId');
      final response = await http.put(
        Uri.parse("$baseUrl/admin/tickets/$ticketId/scan"),
      );
      print('🔵 Scan response status: ${response.statusCode}');
      print('🔵 Scan response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          return {"error": errorData['error'] ?? "Server error: ${response.statusCode}"};
        } catch (_) {
          return {"error": "Server error: ${response.statusCode} - ${response.body}"};
        }
      }
    } catch (e) {
      print('🔴 Error scanning ticket: $e');
      return {"error": "Koneksi server gagal: $e"};
    }
  }

  /// Calculate total revenue from tickets (service fee only)
  int calculateTotalRevenue(List<Ticket> tickets) {
    // Revenue = biaya layanan (service_fee) dari tiket yang sudah terjual
    // Hanya hitung 1x per transaksi (tiket dengan service_fee > 0)
    final Map<String, int> revenuePerTransaction = {};
    
    print('🔵 Calculating revenue from ${tickets.length} tickets');
    
    for (final ticket in tickets) {
      // Hanya hitung tiket yang ACTIVE, USED, atau EXPIRED
      if (!ticket.isActive && !ticket.isUsed && !ticket.isExpired) continue;
      
      // Hanya hitung tiket yang punya service_fee > 0
      if (ticket.serviceFee <= 0) continue;
      
      // Gunakan transaction_id sebagai key, atau id jika tidak ada transaction_id
      final key = ticket.transactionId ?? ticket.id;
      
      print('  Ticket ${ticket.id}: serviceFee=${ticket.serviceFee}, txId=${ticket.transactionId}, key=$key');
      
      // Ambil service_fee tertinggi per transaksi (untuk handle multiple tickets)
      if (!revenuePerTransaction.containsKey(key) || 
          ticket.serviceFee > (revenuePerTransaction[key] ?? 0)) {
        revenuePerTransaction[key] = ticket.serviceFee;
        print('    → Added/Updated: $key = ${ticket.serviceFee}');
      }
    }
    
    final total = revenuePerTransaction.values.fold(0, (sum, fee) => sum + fee);
    print('🔵 Total transactions: ${revenuePerTransaction.length}');
    print('🔵 Total revenue: $total');
    print('🔵 Revenue breakdown: $revenuePerTransaction');
    
    return total;
  }
}
