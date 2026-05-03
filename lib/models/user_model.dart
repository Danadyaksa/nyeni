class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final int completedLevelsTrivia;
  final int completedLevelsLabirin;
  final String createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    required this.completedLevelsTrivia,
    required this.completedLevelsLabirin,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      avatarUrl: json['avatar_url']?.toString(),
      totalXp: json['total_xp'] ?? 0,
      level: json['level'] ?? 1,
      completedLevelsTrivia: json['completed_levels_trivia'] ?? 0,
      completedLevelsLabirin: json['completed_levels_labirin'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
      'total_xp': totalXp,
      'level': level,
      'completed_levels_trivia': completedLevelsTrivia,
      'completed_levels_labirin': completedLevelsLabirin,
      'created_at': createdAt,
    };
  }

  // Helper method untuk cek apakah admin
  bool get isAdmin => role == 'admin';

  // Helper method untuk cek apakah user
  bool get isUser => role == 'user';

  // Copy with method untuk update data
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? avatarUrl,
    int? totalXp,
    int? level,
    int? completedLevelsTrivia,
    int? completedLevelsLabirin,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      completedLevelsTrivia: completedLevelsTrivia ?? this.completedLevelsTrivia,
      completedLevelsLabirin: completedLevelsLabirin ?? this.completedLevelsLabirin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
