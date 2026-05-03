import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';
import '../config/api_config.dart';

class TicketController {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Buy tickets (bulk)
  Future<Map<String, dynamic>> buyTickets({
    required String userId,
    required String eventName,
    required String eventDate,
    required int count,
    required int uniqueCode,
    required int serviceFee,
    required int ticketPrice,
    required int totalAmount,
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

  /// Get user tickets
  Future<List<Ticket>> getMyTickets(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tickets/my-tickets/$userId"),
        headers: {"Content-Type": "application/json"},
      );

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

  /// Filter tickets by status
  List<Ticket> filterTicketsByStatus(List<Ticket> tickets, String status) {
    return tickets.where((ticket) => ticket.status == status).toList();
  }

  /// Get history tickets (USED, EXPIRED, DECLINED)
  List<Ticket> getHistoryTickets(List<Ticket> tickets) {
    return tickets.where((ticket) => 
      ticket.isUsed || ticket.isExpired || ticket.isDeclined
    ).toList();
  }
}
