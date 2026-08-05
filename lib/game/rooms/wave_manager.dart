import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../../core/constants/world_config.dart';
import '../enemies/zombie_enemy.dart';
import '../enemies/soldier_enemy.dart';
import '../enemies/alien_small_enemy.dart';
import '../enemies/alien_boss_enemy.dart';
import '../enemies/masked_elite_enemy.dart';
import 'room_definition.dart';

class WaveManagerComponent extends GameComponent {
  final RoomDefinition room;
  final VoidCallback onAllWavesCleared;
  final Function(int currentWave, int totalWaves, int activeEnemies) onWaveStatusChanged;

  int _currentWaveIndex = 0; // 0-based
  double _timeSinceWaveStarted = 0.0;
  bool _waveInProgress = false;

  final List<Enemy> _spawnedEnemies = [];
  final List<EnemySpawnData> _pendingSpawns = [];

  WaveManagerComponent({
    required this.room,
    required this.onAllWavesCleared,
    required this.onWaveStatusChanged,
  });

  @override
  void update(double dt) {
    super.update(dt);

    // Filter out dead enemies
    _spawnedEnemies.removeWhere((e) => e.isDead);

    // If there's active spawns or currently spawned enemies are alive, we are busy
    if (_waveInProgress) {
      _timeSinceWaveStarted += dt;

      // Handle queued spawns
      final List<EnemySpawnData> spawnedThisFrame = [];
      for (final spawn in _pendingSpawns) {
        if (_timeSinceWaveStarted >= spawn.delay) {
          _spawnEnemy(spawn);
          spawnedThisFrame.add(spawn);
        }
      }
      _pendingSpawns.removeWhere((spawn) => spawnedThisFrame.contains(spawn));

      // Update UI with status
      onWaveStatusChanged(
        _currentWaveIndex, // 1-based current wave
        room.waves.length,
        _spawnedEnemies.length + _pendingSpawns.length,
      );

      // Check if current wave is completed (no more pending and no more alive)
      if (_pendingSpawns.isEmpty && _spawnedEnemies.isEmpty) {
        _waveInProgress = false;
      }
    } else {
      // If we finished the current wave, trigger the next one or clear the level
      if (_currentWaveIndex < room.waves.length) {
        _startNextWave();
      } else {
        // All waves cleared!
        onAllWavesCleared();
        removeFromParent(); // Stop updating
      }
    }
  }

  void _startNextWave() {
    final wave = room.waves[_currentWaveIndex];
    _currentWaveIndex++;
    _timeSinceWaveStarted = 0.0;
    _waveInProgress = true;
    _pendingSpawns.addAll(wave.spawns);

    onWaveStatusChanged(
      _currentWaveIndex,
      room.waves.length,
      _pendingSpawns.length,
    );
  }

  void _spawnEnemy(EnemySpawnData spawn) {
    final world = room.world;
    Enemy enemy;

    // Apply scaling multipliers
    final double health = 50.0 * world.enemyHealthMultiplier;
    final double speed = 70.0 * world.enemySpeedMultiplier;
    final double damage = 12.0 * world.enemyDamageMultiplier;

    switch (spawn.type) {
      case EnemyType.zombie:
        enemy = ZombieEnemy(
          position: spawn.position,
          health: health,
          speed: speed,
          damage: damage,
        );
        break;
      case EnemyType.soldier:
        enemy = SoldierEnemy(
          position: spawn.position,
          health: health * 1.2,
          speed: speed * 1.1,
          damage: damage * 1.2,
        );
        break;
      case EnemyType.alienSmall:
        enemy = AlienSmallEnemy(
          position: spawn.position,
          health: health * 0.6,
          speed: speed * 1.3,
          damage: damage * 0.7,
        );
        break;
      case EnemyType.alienBoss:
        enemy = AlienBossEnemy(
          position: spawn.position,
          health: health * 3.5,
          speed: speed * 0.75,
          damage: damage * 2.0,
        );
        break;
      case EnemyType.maskedElite:
        enemy = MaskedEliteEnemy(
          position: spawn.position,
          health: health * 1.6,
          speed: speed * 1.2,
          damage: damage * 1.5,
        );
        break;
    }

    gameRef.add(enemy);
    _spawnedEnemies.add(enemy);
  }
}
