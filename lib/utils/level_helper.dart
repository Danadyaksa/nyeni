import 'package:flutter/material.dart';

/// Helper untuk sistem level & XP
class LevelHelper {
  // XP requirements per level (minimum XP untuk MASUK level tersebut)
  static const Map<int, int> _levelXP = {
    1: 0,      // Level 1: 0-99 XP
    2: 100,    // Level 2: 100-249 XP
    3: 250,    // Level 3: 250-449 XP
    4: 450,    // Level 4: 450-699 XP
    5: 700,    // Level 5: 700-999 XP
    6: 1000,   // Level 6: 1000-1349 XP
    7: 1350,   // Level 7: 1350-1749 XP
    8: 1750,   // Level 8: 1750-2199 XP
    9: 2200,   // Level 9: 2200-2699 XP
    10: 2700,  // Level 10: 2700+ XP (max)
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
        return const Color(0xFFF59E0B); // Bright Gold
      case 'Silver':
        return const Color(0xFF64748B); // Darker Silver
      default:
        return const Color(0xFFD97706); // Bright Bronze/Orange
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
