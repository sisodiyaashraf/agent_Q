import 'package:flutter/material.dart';

enum EnemyType { zombie, soldier, alienSmall, alienBoss, maskedElite }

class WorldDefinition {
  final int id;
  final String name;
  final Color primaryColor;
  final Color floorColor;
  final Color wallColor;
  final double enemyHealthMultiplier;
  final double enemySpeedMultiplier;
  final double enemyDamageMultiplier;
  final List<EnemyType> allowedEnemies;

  const WorldDefinition({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.floorColor,
    required this.wallColor,
    required this.enemyHealthMultiplier,
    required this.enemySpeedMultiplier,
    required this.enemyDamageMultiplier,
    required this.allowedEnemies,
  });
}

class WorldConfig {
  static const int totalLevels = 50;
  static const int levelsPerWorld = 10;
  static const double gameHeight = 768.0;
  static const double floorY = 665.0;
  static const double gravity = 900.0;

  static const List<WorldDefinition> worlds = [
    WorldDefinition(
      id: 1,
      name: 'Sector Alpha: The Quarantine',
      primaryColor: Color(0xFF4CAF50), // Green
      floorColor: Color(0xFF1E2F21),
      wallColor: Color(0xFF2E4F32),
      enemyHealthMultiplier: 1.0,
      enemySpeedMultiplier: 1.0,
      enemyDamageMultiplier: 1.0,
      allowedEnemies: [EnemyType.zombie, EnemyType.alienSmall],
    ),
    WorldDefinition(
      id: 2,
      name: 'Sector Beta: Military Outpost',
      primaryColor: Color(0xFF3F51B5), // Indigo
      floorColor: Color(0xFF1F2235),
      wallColor: Color(0xFF2C315E),
      enemyHealthMultiplier: 1.3,
      enemySpeedMultiplier: 1.1,
      enemyDamageMultiplier: 1.2,
      allowedEnemies: [EnemyType.zombie, EnemyType.soldier],
    ),
    WorldDefinition(
      id: 3,
      name: 'Sector Gamma: Alien Hive',
      primaryColor: Color(0xFF9C27B0), // Purple
      floorColor: Color(0xFF2E1B36),
      wallColor: Color(0xFF4F2A61),
      enemyHealthMultiplier: 1.7,
      enemySpeedMultiplier: 1.2,
      enemyDamageMultiplier: 1.5,
      allowedEnemies: [EnemyType.alienSmall, EnemyType.soldier],
    ),
    WorldDefinition(
      id: 4,
      name: 'Sector Delta: Industrial Labs',
      primaryColor: Color(0xFFFF9800), // Orange
      floorColor: Color(0xFF332514),
      wallColor: Color(0xFF5C411E),
      enemyHealthMultiplier: 2.2,
      enemySpeedMultiplier: 1.3,
      enemyDamageMultiplier: 1.8,
      allowedEnemies: [
        EnemyType.zombie,
        EnemyType.soldier,
        EnemyType.maskedElite,
      ],
    ),
    WorldDefinition(
      id: 5,
      name: 'Sector Omega: Quantum Core',
      primaryColor: Color(0xFFE91E63), // Pink/Red
      floorColor: Color(0xFF3A1C28),
      wallColor: Color(0xFF64263E),
      enemyHealthMultiplier: 3.0,
      enemySpeedMultiplier: 1.5,
      enemyDamageMultiplier: 2.5,
      allowedEnemies: [
        EnemyType.zombie,
        EnemyType.soldier,
        EnemyType.alienSmall,
        EnemyType.maskedElite,
      ],
    ),
  ];

  /// Get the world definition for a given level (1-50).
  static WorldDefinition getWorldForLevel(int level) {
    final worldId = ((level - 1) ~/ levelsPerWorld) + 1;
    final index = (worldId - 1).clamp(0, worlds.length - 1);
    return worlds[index];
  }

  /// Check if a level is a boss level (levels 10, 20, 30, 40, 50).
  static bool isBossLevel(int level) {
    return level > 0 && level % levelsPerWorld == 0;
  }
}
