import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../../core/constants/world_config.dart';
import '../../services/sound_service.dart';
import '../mixins/game_feel.dart';

class AgentQComponent extends SimplePlayer with BlockMovementCollision, GameFeelMixin {
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

  // Overhauled movement physics variables
  double _velocityX = 0.0;
  double _inputX = 0.0;
  double _footstepTimer = 0.0;
  double _bobTimer = 0.0;

  // Dash variables
  bool _isDashing = false;
  bool get isDashing => _isDashing;
  double _dashTimer = 0.0;
  double _dashCooldown = 0.0;

  // Punch combo variables
  int _punchCombo = 0;
  double _lastPunchTime = 0.0;

  AgentQComponent({
    required super.position,
    required this.onHealthChanged,
    required this.onAmmoChanged,
    required this.onDeath,
  }) : super(
          size: Vector2(120, 131),
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

    if (event.directional == JoystickMoveDirectional.IDLE) {
      _inputX = 0.0;
    } else {
      _inputX = cos(event.radAngle) > 0 ? 1.0 : -1.0;
      lastDirection = _inputX > 0 ? Direction.right : Direction.left;
    }
  }

  @override
  Future<void> onLoad() async {
    final walkSheet = SpriteSheet(
      image: Flame.images.fromCache('characters/walk_cycle_agent_Q.png'),
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    animation = SimpleDirectionAnimation(
      enabledFlipX: true,
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
        size: Vector2(50, 105),
        position: Vector2(35, 25),
      ),
    );
    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (GameFeel.hitStopTimer > 0) {
      return;
    }

    super.update(dt);
    if (isDead) return;

    // Smooth camera lookahead follow
    if (hasGameRef) {
      gameRef.camera.stop(); // stop hard tracking
      final double lookaheadOffset = lastDirection == Direction.left ? -65.0 : 65.0;
      final double targetCamX = position.x + size.x / 2 + lookaheadOffset;
      final double targetCamY = position.y + size.y / 2 - 15.0;
      gameRef.camera.moveTo(Vector2(targetCamX, targetCamY));
    }

    // Decelerate dash cooldown
    if (_dashCooldown > 0) {
      _dashCooldown -= dt;
    }

    // Handle Dash state
    if (_isDashing) {
      _dashTimer -= dt;
      speed = 340.0;
      if (lastDirection == Direction.left) {
        moveLeft();
      } else {
        moveRight();
      }
      if (_dashTimer <= 0) {
        _isDashing = false;
        speed = 130.0;
      }
      return; // Skip normal movement/physics while dashing
    }

    // Apply knockback friction/movement from GameFeelMixin
    updateKnockback(dt);

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

    // Apply gravity and jumping calculations (overhauled jump arc easing)
    if (_isJumping) {
      _bobTimer = 0.0;
      // Apply stronger gravity on descent than ascent (snappy, weighted feel)
      final double currentGravity = _velocityY > 0 ? WorldConfig.gravity * 1.7 : WorldConfig.gravity;
      _velocityY += currentGravity * dt;
      position.y += _velocityY * dt;
      if (position.y >= WorldConfig.floorY - size.y) {
        position.y = WorldConfig.floorY - size.y;
        _velocityY = 0.0;
        _isJumping = false;
        SoundService.play('land.wav');
        // Squash on land
        add(
          ScaleEffect.to(
            Vector2(1.2, 0.8),
            EffectController(duration: 0.08, reverseDuration: 0.08),
          ),
        );
      }
    } else {
      position.y = WorldConfig.floorY - size.y;
    }

    // Overhauled movement physics: Acceleration & Deceleration
    final double targetVelocityX = _inputX * 130.0;
    if (_inputX != 0) {
      // Accelerate towards target speed
      _velocityX += (targetVelocityX - _velocityX) * (1.0 - exp(-11.0 * dt));
    } else {
      // Slide/decelerate to a stop
      _velocityX += (0.0 - _velocityX) * (1.0 - exp(-16.0 * dt));
    }

    // Apply horizontal velocity
    if (_velocityX.abs() > 3.0) {
      speed = _velocityX.abs();
      if (_velocityX > 0) {
        moveRight();
      } else {
        moveLeft();
      }

      // Footstep loop SFX triggering
      if (!_isJumping) {
        _footstepTimer -= dt;
        if (_footstepTimer <= 0) {
          SoundService.play('footstep.wav');
          _footstepTimer = 0.32; // Play step audio every 320ms of running
        }
        // Run bobbing scale effect
        if (!_isDashing && children.whereType<ScaleEffect>().isEmpty) {
          _bobTimer += dt * 12.0;
          scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.05);
        }
      }
    } else {
      _velocityX = 0.0;
      _footstepTimer = 0.0;
      _bobTimer = 0.0;
      if (!_isJumping) {
        idle();
        if (children.whereType<ScaleEffect>().isEmpty) {
          scale = Vector2.all(1.0);
        }
      }
    }

    // Reset combo punch status if idle for too long
    final double now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (now - _lastPunchTime > 0.55) {
      _punchCombo = 0;
    }

    // Keep player within horizontal map boundaries
    final mapWidth = gameRef.map.size.x;
    if (position.x < 0) {
      position.x = 0;
      _velocityX = 0.0;
    } else if (position.x > mapWidth - size.x) {
      position.x = mapWidth - size.x;
      _velocityX = 0.0;
    }
  }

  void jump() {
    if (isDead || _isJumping || _isDashing) return;
    _isJumping = true;
    _velocityY = -360.0; // Snappy jump force
    SoundService.play('jump.wav');

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

    // Stretch on jump start
    add(
      ScaleEffect.to(
        Vector2(0.85, 1.25),
        EffectController(duration: 0.12, reverseDuration: 0.12),
      ),
    );
  }

  void dash() {
    if (isDead || _isDashing || _isJumping || _dashCooldown > 0) return;
    _isDashing = true;
    _dashTimer = 0.18; // Short dash duration (180ms)
    _dashCooldown = 0.6; // 600ms cooldown before next dash
    SoundService.play('jump.wav');

    // Add immediate dash horizontal speed speed boost
    _velocityX = lastDirection == Direction.left ? -340.0 : 340.0;

    // Squish scale effect to simulate momentum stretch
    add(
      ScaleEffect.to(
        Vector2(1.25, 0.75),
        EffectController(duration: 0.08, reverseDuration: 0.1),
      ),
    );
  }

  void punch() {
    if (isDead || _isJumping || _isDashing) return;

    final double now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (now - _lastPunchTime <= 0.55) {
      _punchCombo = (_punchCombo + 1) % 3;
    } else {
      _punchCombo = 0;
    }
    _lastPunchTime = now;

    final walkImage = Flame.images.fromCache('characters/walk_cycle_agent_Q.png');
    final walkSheet = SpriteSheet(
      image: walkImage,
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    // If combo is 2 (3rd hit), play heavy punch cols 3-5, else normal punch cols 0-2
    SpriteAnimation punchAnim;
    if (_punchCombo == 2) {
      punchAnim = SpriteAnimation.variableSpriteList([
        walkSheet.getSprite(2, 3),
        walkSheet.getSprite(2, 4),
        walkSheet.getSprite(2, 5),
      ], stepTimes: [0.05, 0.05, 0.05]);
    } else {
      punchAnim = SpriteAnimation.variableSpriteList([
        walkSheet.getSprite(2, 0),
        walkSheet.getSprite(2, 1),
        walkSheet.getSprite(2, 2),
      ], stepTimes: [0.05, 0.05, 0.05]);
    }

    animation?.playOnce(punchAnim, flipX: lastDirection == Direction.left);
    SoundService.play('punch.wav');

    final Future<SpriteAnimation> impactStarAnim = Future.value(
      SpriteAnimation.fromFrameData(
        Flame.images.fromCache('impact_star.png'),
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: 0.07,
          textureSize: Vector2(32, 32),
          loop: false,
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 50), () {
      if (isDead) return;

      final isComboHit = _punchCombo == 2;
      final double punchDamage = isComboHit ? 30.0 : 15.0;

      simpleAttackMelee(
        damage: punchDamage,
        size: Vector2(60, 60),
        withPush: true,
        animationRight: impactStarAnim,
      );

      // Extra feel for the final combo hit
      if (isComboHit) {
        GameFeel.triggerHitStop(0.08); // 80ms freeze-frame
        GameFeel.triggerScreenShake(this, duration: 0.15, intensity: 5.0);
      }
    });
  }

  void shoot() {
    if (isDead || _isReloading || _fireCooldown > 0 || _isDashing) return;

    if (ammo <= 0) {
      _isReloading = true;
      _reloadTimer = _reloadTime;
      onAmmoChanged(ammo, maxAmmo, _isReloading);
      SoundService.play('reload.wav');
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
    SoundService.play('shoot.wav');

    ammo--;
    onAmmoChanged(ammo, maxAmmo, _isReloading);

    if (ammo <= 0) {
      _isReloading = true;
      _reloadTimer = _reloadTime;
      onAmmoChanged(ammo, maxAmmo, _isReloading);
      SoundService.play('reload.wav');
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (isDead) return;
      simpleAttackRangeByAngle(
        angle: angle,
        damage: 20.0,
        size: Vector2(8, 8),
        speed: 370.0,
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
    if (isDead || _isDashing) return;

    if (shield > 0) {
      if (shield >= damage) {
        shield -= damage;
        damage = 0.0;
      } else {
        damage -= shield;
        shield = 0.0;
      }
    }

    // Play hit sound
    SoundService.play('hit.wav');

    // Trigger visual hit-stop & shake for feedback
    GameFeel.triggerHitStop(0.05); // 50ms freeze on hit
    GameFeel.triggerScreenShake(this, duration: 0.12, intensity: 3.5);

    // Spawn damage floating text
    spawnDamageText(damage, color: Colors.blueAccent);

    // Add physical knockback push-back
    final attackerPos = (identify is GameComponent) ? identify.position.x : position.x - 20;
    final fromLeft = attackerPos < position.x;
    applyKnockback(160.0, fromLeft);

    // Add brief red tint effect
    final colorEffect = ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 0.15, reverseDuration: 0.15),
    );
    add(colorEffect);

    // Briefly squish character height to simulate hit impact force
    add(
      ScaleEffect.to(
        Vector2(1.15, 0.85),
        EffectController(duration: 0.08, reverseDuration: 0.08),
      ),
    );

    super.onReceiveDamage(attacker, damage, identify);
    onHealthChanged(life, maxHealth, shield, maxShield);
  }

  @override
  void onDie() {
    SoundService.play('death.wav');
    super.onDie();
    onDeath();
  }
}
