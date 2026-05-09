import 'event_model.dart';

class Recommendation {
  final bool hasHistory;
  final String? category;
  final String message;
  final List<Event> events;

  Recommendation({
    required this.hasHistory,
    this.category,
    required this.message,
    required this.events,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      hasHistory: json['hasHistory'] ?? false,
      category: json['category'],
      message: json['message'] ?? '',
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasHistory': hasHistory,
      'category': category,
      'message': message,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}
