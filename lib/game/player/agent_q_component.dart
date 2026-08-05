import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

class AgentQComponent extends SimplePlayer with BlockMovementCollision {
  static const double maxHealth = 100.0;

  final Function(double current, double max) onHealthChanged;
  final VoidCallback onDeath;

  double _fireCooldown = 0.0;
  final double _fireRate = 0.35; // Seconds between shots
  final double _aimRange = 180.0; // Distance to target

  AgentQComponent({
    required super.position,
    required SpriteAnimation idleAnimation,
    required SpriteAnimation runAnimation,
    required this.onHealthChanged,
    required this.onDeath,
  }) : super(
          size: Vector2(32, 32),
          life: maxHealth,
          speed: 130.0,
          animation: SimpleDirectionAnimation(
            idleRight: idleAnimation,
            runRight: runAnimation,
          ),
        );

  @override
  Future<void> onLoad() async {
    // Add hitbox slightly smaller than sprite for fairer collisions
    add(
      RectangleHitbox(
        size: Vector2(20, 24),
        position: Vector2(6, 4),
      ),
    );
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    _fireCooldown -= dt;
    if (_fireCooldown <= 0) {
      _autoAimAndShoot();
    }
  }

  void _autoAimAndShoot() {
    if (gameRef.enemies().isEmpty) return;

    // Filter alive enemies and find the nearest one within range
    final playerCenter = center;
    Enemy? closestEnemy;
    double minDistance = _aimRange;

    for (final enemy in gameRef.enemies()) {
      if (enemy.isDead) continue;
      final enemyCenter = enemy.center;
      final dist = (enemyCenter - playerCenter).length;
      if (dist < minDistance) {
        minDistance = dist;
        closestEnemy = enemy;
      }
    }

    if (closestEnemy != null) {
      final enemyCenter = closestEnemy.center;
      final angle = atan2(enemyCenter.y - playerCenter.y, enemyCenter.x - playerCenter.x);

      // Fire projectile
      simpleAttackRangeByAngle(
        angle: angle,
        damage: 20.0,
        size: Vector2(8, 8),
        speed: 260.0,
        attackFrom: AttackOriginEnum.PLAYER_OR_ALLY,
        animation: Future.value(
          SpriteAnimation.fromFrameData(
            Flame.images.fromCache('bullet.png'),
            SpriteAnimationData.sequenced(
              amount: 1,
              stepTime: 1.0,
              textureSize: Vector2(16, 16),
            ),
          ),
        ),
      );

      // Reset cooldown
      _fireCooldown = _fireRate;
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    if (isDead) return;
    super.onReceiveDamage(attacker, damage, identify);
    onHealthChanged(life, maxHealth);
  }

  @override
  void onDie() {
    super.onDie();
    onDeath();
  }
}
