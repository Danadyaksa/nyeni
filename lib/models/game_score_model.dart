class GameScore {
  final int id;
  final String userId;
  final String gameType; // 'trivia' or 'labirin'
  final int score;
  final int level;
  final String createdAt;

  GameScore({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.score,
    required this.level,
    required this.createdAt,
  });

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      gameType: json['game_type']?.toString() ?? '',
      score: json['score'] ?? 0,
      level: json['level'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_type': gameType,
      'score': score,
      'level': level,
      'created_at': createdAt,
    };
  }

  // Helper methods
  bool get isTrivia => gameType == 'trivia';
  bool get isLabirin => gameType == 'labirin';

  String get gameTypeName {
    switch (gameType) {
      case 'trivia':
        return 'Trivia Quiz';
      case 'labirin':
        return 'Gyro Labyrinth';
      default:
        return gameType;
    }
  }
}
