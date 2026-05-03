class Feedback {
  final int id;
  final String userId;
  final String feedbackText;
  final String createdAt;
  final String? userName; // From JOIN with users table
  final String? userEmail; // From JOIN with users table

  Feedback({
    required this.id,
    required this.userId,
    required this.feedbackText,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      feedbackText: json['feedback_text']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['full_name']?.toString(),
      userEmail: json['user_email']?.toString() ?? json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'feedback_text': feedbackText,
      'created_at': createdAt,
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}
