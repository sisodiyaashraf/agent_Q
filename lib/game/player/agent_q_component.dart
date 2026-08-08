import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../../core/constants/world_config.dart';

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

  bool _isJumping = false;
  bool get isJumping => _isJumping;
  double _velocityY = 0.0;

  AgentQComponent({
    required super.position,
    required this.onHealthChanged,
    required this.onAmmoChanged,
    required this.onDeath,
  }) : super(
          size: Vector2(96, 105),
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
  void onJoystickChangeDirectional(JoystickDirectionalEvent event) {
    if (isDead) return;

    double targetAngle = event.radAngle;
    if (event.directional != JoystickMoveDirectional.IDLE) {
      final isMovingRight = cos(event.radAngle) > 0;
      targetAngle = isMovingRight ? 0.0 : pi;
    }

    final horizontalEvent = JoystickDirectionalEvent(
      directional: event.directional,
      intensity: event.intensity,
      radAngle: targetAngle,
      isKeyboard: event.isKeyboard,
    );
    super.onJoystickChangeDirectional(horizontalEvent);
  }

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

    add(
      RectangleHitbox(
        size: Vector2(40, 85),
        position: Vector2(28, 20),
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

    if (_fireCooldown > 0) {
      _fireCooldown -= dt;
    }

    // Apply gravity and jumping calculations
    if (_isJumping) {
      _velocityY += WorldConfig.gravity * dt;
      position.y += _velocityY * dt;
      if (position.y >= WorldConfig.floorY - size.y) {
        position.y = WorldConfig.floorY - size.y;
        _velocityY = 0.0;
        _isJumping = false;
      }
    } else {
      // Force Y constraint
      position.y = WorldConfig.floorY - size.y;
    }

    // Keep player within horizontal map boundaries
    final mapWidth = gameRef.map.size.x;
    if (position.x < 0) {
      position.x = 0;
    } else if (position.x > mapWidth - size.x) {
      position.x = mapWidth - size.x;
    }
  }

  void jump() {
    if (isDead || _isJumping) return;
    _isJumping = true;
    _velocityY = -350.0; // Jump force

    // Play jump animation (upward facing stand frame)
    final walkImage = Flame.images.fromCache('characters/walk_cycle_agent_Q.png');
    final walkSheet = SpriteSheet(
      image: walkImage,
      srcSize: Vector2(677 / 6, 369 / 3),
    );
    final jumpAnim = SpriteAnimation.variableSpriteList([
      walkSheet.getSprite(0, 5),
    ], stepTimes: [1.0]);
    animation?.playOnce(jumpAnim, flipX: lastDirection == Direction.left);
  }

  void punch() {
    if (isDead || _isJumping) return;

    // Play punch swing animation using row 2 columns 0-2
    final walkImage = Flame.images.fromCache('characters/walk_cycle_agent_Q.png');
    final walkSheet = SpriteSheet(
      image: walkImage,
      srcSize: Vector2(677 / 6, 369 / 3),
    );
    final punchAnim = SpriteAnimation.variableSpriteList([
      walkSheet.getSprite(2, 0),
      walkSheet.getSprite(2, 1),
      walkSheet.getSprite(2, 2),
    ], stepTimes: [0.06, 0.06, 0.06]);

    animation?.playOnce(punchAnim, flipX: lastDirection == Direction.left);

    final Future<SpriteAnimation> impactStarAnim = Future.value(
      SpriteAnimation.fromFrameData(
        Flame.images.fromCache('impact_star.png'),
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: 0.08,
          textureSize: Vector2(32, 32),
          loop: false,
        ),
      ),
    );

    // Delay the melee hit-detection and impact star to align with the strike frame specifically (frame 1)
    Future.delayed(const Duration(milliseconds: 60), () {
      if (isDead) return;
      simpleAttackMelee(
        damage: 15.0,
        size: Vector2(50, 50),
        withPush: true,
        animationRight: impactStarAnim,
      );
    });
  }

  void shoot() {
    if (isDead || _isReloading || _fireCooldown > 0) return;

    if (ammo <= 0) {
      _isReloading = true;
      _reloadTimer = _reloadTime;
      onAmmoChanged(ammo, maxAmmo, _isReloading);
      return;
    }

    double angle = 0.0;
    bool isLeft = false;
    if (lastDirection == Direction.left) {
      angle = pi;
      isLeft = true;
    } else if (lastDirection == Direction.right) {
      angle = 0.0;
      isLeft = false;
    } else if (lastDirection == Direction.up) {
      angle = -pi / 2;
    } else if (lastDirection == Direction.down) {
      angle = pi / 2;
    }

    final shootImage = Flame.images.fromCache('characters/Shooting_animation_aq.png');
    final shootSheet = SpriteSheet(
      image: shootImage,
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    SpriteAnimation shootAnim;
    if (lastDirection == Direction.up) {
      shootAnim = SpriteAnimation.variableSpriteList([
        shootSheet.getSprite(0, 5),
        shootSheet.getSprite(1, 0),
        shootSheet.getSprite(1, 1),
        shootSheet.getSprite(1, 2),
        shootSheet.getSprite(1, 3),
      ], stepTimes: List.filled(5, 0.05));
    } else if (lastDirection == Direction.down) {
      shootAnim = SpriteAnimation.variableSpriteList([
        shootSheet.getSprite(0, 1),
        shootSheet.getSprite(0, 2),
        shootSheet.getSprite(0, 3),
      ], stepTimes: List.filled(3, 0.08));
    } else {
      shootAnim = SpriteAnimation.variableSpriteList([
        shootSheet.getSprite(2, 0),
        shootSheet.getSprite(2, 1),
        shootSheet.getSprite(2, 2),
        shootSheet.getSprite(2, 3),
        shootSheet.getSprite(2, 4),
        shootSheet.getSprite(2, 5),
      ], stepTimes: List.filled(6, 0.05));
    }

    animation?.playOnce(shootAnim, flipX: isLeft);

    ammo--;
    onAmmoChanged(ammo, maxAmmo, _isReloading);

    if (ammo <= 0) {
      _isReloading = true;
      _reloadTimer = _reloadTime;
      onAmmoChanged(ammo, maxAmmo, _isReloading);
    }

    // Delay bullet spawn slightly to visually sync with the shooting muzzle flash frame
    Future.delayed(const Duration(milliseconds: 150), () {
      if (isDead) return;
      simpleAttackRangeByAngle(
        angle: angle,
        damage: 20.0,
        size: Vector2(8, 8),
        speed: 350.0,
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
    });

    _fireCooldown = _fireRate;
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

    // Add brief red tint effect
    final colorEffect = ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 0.15, reverseDuration: 0.15),
    );
    add(colorEffect);

    // Briefly squish character height to simulate hit impact force
    add(
      ScaleEffect.to(
        Vector2(1.1, 0.9),
        EffectController(duration: 0.08, reverseDuration: 0.08),
      ),
    );

    super.onReceiveDamage(attacker, damage, identify);
    onHealthChanged(life, maxHealth, shield, maxShield);
  }

  @override
  void onDie() {
    super.onDie();
    onDeath();
  }
}
