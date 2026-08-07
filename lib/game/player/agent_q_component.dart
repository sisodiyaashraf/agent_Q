import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

class AgentQComponent extends SimplePlayer with BlockMovementCollision {
  static const double maxHealth = 100.0;

  final Function(double current, double max, double shield, double maxShield) onHealthChanged;
  final Function(int current, int max, bool reloading) onAmmoChanged;
  final VoidCallback onDeath;

  int ammo = 30;
  final int maxAmmo = 30;
  double shield = 0.0;
  final double maxShield = 50.0;

  bool _isReloading = false;
  bool get isReloading => _isReloading;
  double _reloadTimer = 0.0;
  final double _reloadTime = 1.5;

  double _fireCooldown = 0.0;
  final double _fireRate = 0.35; // Seconds between shots
  final double _aimRange = 180.0; // Distance to target

  AgentQComponent({
    required super.position,
    required this.onHealthChanged,
    required this.onAmmoChanged,
    required this.onDeath,
  }) : super(
          size: Vector2(32, 32),
          life: maxHealth,
          speed: 130.0,
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/walk_cycle_agent_Q.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(4 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/walk_cycle_agent_Q.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(5 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    final walkSheet = SpriteSheet(
      image: Flame.images.fromCache('characters/walk_cycle_agent_Q.png'),
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    animation = SimpleDirectionAnimation(
      idleRight: walkSheet.createAnimation(row: 1, stepTime: 0.15, from: 4, to: 5),
      runRight: SpriteAnimation.variableSpriteList([
        walkSheet.getSprite(1, 5),
        walkSheet.getSprite(2, 0),
        walkSheet.getSprite(2, 1),
        walkSheet.getSprite(2, 2),
        walkSheet.getSprite(2, 3),
        walkSheet.getSprite(2, 4),
        walkSheet.getSprite(2, 5),
      ], stepTimes: List.filled(7, 0.1)),
      idleDown: walkSheet.createAnimation(row: 0, stepTime: 0.15, from: 0, to: 1),
      runDown: SpriteAnimation.variableSpriteList([
        walkSheet.getSprite(0, 1),
        walkSheet.getSprite(0, 2),
        walkSheet.getSprite(0, 3),
      ], stepTimes: List.filled(3, 0.15)),
      idleUp: walkSheet.createAnimation(row: 0, stepTime: 0.15, from: 4, to: 5),
      runUp: SpriteAnimation.variableSpriteList([
        walkSheet.getSprite(0, 5),
        walkSheet.getSprite(1, 0),
        walkSheet.getSprite(1, 1),
        walkSheet.getSprite(1, 2),
        walkSheet.getSprite(1, 3),
      ], stepTimes: List.filled(5, 0.12)),
    );

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

    if (_isReloading) {
      _reloadTimer -= dt;
      if (_reloadTimer <= 0) {
        _isReloading = false;
        ammo = maxAmmo;
        onAmmoChanged(ammo, maxAmmo, _isReloading);
      }
    }

    _fireCooldown -= dt;
    if (_fireCooldown <= 0 && !_isReloading) {
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

      // Consume ammo
      ammo--;
      onAmmoChanged(ammo, maxAmmo, _isReloading);

      if (ammo <= 0) {
        _isReloading = true;
        _reloadTimer = _reloadTime;
        onAmmoChanged(ammo, maxAmmo, _isReloading);
      }

      // Play shooting animation based on target angle/direction
      final shootImage = Flame.images.fromCache('characters/Shooting_animation_aq.png');
      final shootSheet = SpriteSheet(
        image: shootImage,
        srcSize: Vector2(677 / 6, 369 / 3),
      );

      final dx = enemyCenter.x - playerCenter.x;
      final dy = enemyCenter.y - playerCenter.y;
      SpriteAnimation shootAnim;
      bool flipH = false;

      if (dx.abs() > dy.abs()) {
        flipH = dx < 0;
        shootAnim = SpriteAnimation.variableSpriteList([
          shootSheet.getSprite(2, 0),
          shootSheet.getSprite(2, 1),
          shootSheet.getSprite(2, 2),
          shootSheet.getSprite(2, 3),
          shootSheet.getSprite(2, 4),
          shootSheet.getSprite(2, 5),
        ], stepTimes: List.filled(6, 0.05));
      } else {
        if (dy < 0) {
          shootAnim = SpriteAnimation.variableSpriteList([
            shootSheet.getSprite(0, 5),
            shootSheet.getSprite(1, 0),
            shootSheet.getSprite(1, 1),
            shootSheet.getSprite(1, 2),
            shootSheet.getSprite(1, 3),
          ], stepTimes: List.filled(5, 0.05));
        } else {
          shootAnim = SpriteAnimation.variableSpriteList([
            shootSheet.getSprite(0, 1),
            shootSheet.getSprite(0, 2),
            shootSheet.getSprite(0, 3),
          ], stepTimes: List.filled(3, 0.08));
        }
      }

      animation?.playOnce(shootAnim, flipX: flipH);

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

  void refillAmmo() {
    ammo = maxAmmo;
    _isReloading = false;
    _reloadTimer = 0.0;
    onAmmoChanged(ammo, maxAmmo, _isReloading);
  }

  void addShield(double amount) {
    shield = (shield + amount).clamp(0.0, maxShield);
    onHealthChanged(life, maxHealth, shield, maxShield);
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    if (isDead) return;

    if (shield > 0) {
      if (shield >= damage) {
        shield -= damage;
        damage = 0.0;
      } else {
        damage -= shield;
        shield = 0.0;
      }
    }

    super.onReceiveDamage(attacker, damage, identify);
    onHealthChanged(life, maxHealth, shield, maxShield);
  }

  @override
  void onDie() {
    super.onDie();
    onDeath();
  }
}
