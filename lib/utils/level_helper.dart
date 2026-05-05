import 'package:flutter/material.dart';

/// Helper untuk sistem level & XP
class LevelHelper {
  // XP requirements per level
  static const Map<int, int> _levelXP = {
    1: 0,
    2: 100,
    3: 250,
    4: 450,
    5: 700,
    6: 1000,
    7: 1350,
    8: 1750,
    9: 2200,
    10: 2700,
  };

  /// Get level tier (Bronze, Silver, Gold)
  static String getTier(int level) {
    if (level >= 7) return 'Gold';
    if (level >= 4) return 'Silver';
    return 'Bronze';
  }

  /// Get tier color
  static Color getTierColor(int level) {
    final tier = getTier(level);
    switch (tier) {
      case 'Gold':
        return const Color(0xFFEAB308); // Gold
      case 'Silver':
        return const Color(0xFF94A3B8); // Silver
      default:
        return const Color(0xFF92400E); // Bronze
    }
  }

  /// Get XP required for next level
  static int getNextLevelXP(int currentLevel) {
    if (currentLevel >= 10) return _levelXP[10]!;
    return _levelXP[currentLevel + 1] ?? 0;
  }

  /// Get XP required for current level
  static int getCurrentLevelXP(int currentLevel) {
    return _levelXP[currentLevel] ?? 0;
  }

  /// Calculate progress to next level (0.0 - 1.0)
  static double getProgress(int currentXP, int currentLevel) {
    if (currentLevel >= 10) return 1.0;
    
    final currentLevelXP = getCurrentLevelXP(currentLevel);
    final nextLevelXP = getNextLevelXP(currentLevel);
    final xpInCurrentLevel = currentXP - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    
    if (xpNeededForNextLevel <= 0) return 1.0;
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  /// Get XP remaining to next level
  static int getXPRemaining(int currentXP, int currentLevel) {
    if (currentLevel >= 10) return 0;
    final nextLevelXP = getNextLevelXP(currentLevel);
    return (nextLevelXP - currentXP).clamp(0, double.infinity).toInt();
  }

  /// Calculate level from XP
  static int calculateLevel(int xp) {
    for (int level = 10; level >= 1; level--) {
      if (xp >= _levelXP[level]!) return level;
    }
    return 1;
  }

  /// Get all level thresholds
  static Map<int, int> getLevelThresholds() {
    return Map.from(_levelXP);
  }
}
