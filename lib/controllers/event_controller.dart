import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../config/api_config.dart';

class EventController {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Get all events
  Future<List<Event>> getAllEvents() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/events"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Get events error: $e");
      return [];
    }
  }

  /// Get event detail by ID
  Future<Event?> getEventDetail(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/events/$id"));
      if (response.statusCode == 200) {
        return Event.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Get event detail error: $e");
      return null;
    }
  }

  /// Search events by name
  List<Event> searchEvents(List<Event> events, String query) {
    if (query.isEmpty) return events;
    return events.where((event) => 
      event.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
