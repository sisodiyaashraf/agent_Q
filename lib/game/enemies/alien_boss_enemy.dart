import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../../core/constants/world_config.dart';
import '../../services/sound_service.dart';
import '../items/pickup_component.dart';
import '../mixins/game_feel.dart';
import 'enemy_health_bar.dart';

class AlienBossEnemy extends SimpleEnemy with BlockMovementCollision, GameFeelMixin {
  final double damage;
  double _actionTimer = 3.0;
  bool _isPerformingAttack = false;
  double _bobTimer = 0.0;

  AlienBossEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(192, 210), // Double standard size
          life: health * 3.5, // Boss tier health pool
          speed: speed * 0.5, // Slow boss movement
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Boss_alien_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(4 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Boss_alien_enemy.png'),
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
      image: Flame.images.fromCache('characters/Boss_alien_enemy.png'),
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
      ], stepTimes: List.filled(7, 0.15)),
    );

    add(
      RectangleHitbox(
        size: Vector2(144, 144),
        position: Vector2(24, 30),
      ),
    );
    add(EnemyHealthBar());
    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (GameFeel.hitStopTimer > 0) return;

    super.update(dt);
    if (isDead) {
      scale = Vector2.all(1.0);
      return;
    }

    // Constrain enemy Y position to floor
    position.y = WorldConfig.floorY - size.y;

    // Apply knockback
    updateKnockback(dt);

    final isMoving = velocity.x != 0 || velocity.y != 0;
    if (isMoving && knockbackX == 0) {
      _bobTimer += dt * 8; // Boss is slower, slower bob
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.05);
    } else {
      scale = Vector2.all(1.0);
    }

    _actionTimer -= dt;
    if (_actionTimer <= 0 && knockbackX == 0) {
      _executeRadialAttack();
      _actionTimer = 4.5; // Cooldown between boss special attacks
    }

    if (!_isPerformingAttack && !isDead && knockbackX == 0) {
      final player = gameRef.player;
      if (player != null && !player.isDead) {
        seeAndMoveToPlayer(
          closePlayer: (p) {
            _executeMeleeCrush();
          },
          radiusVision: 600.0,
          observed: () {},
          notObserved: () {
            moveToPosition(player.position, speed: speed);
            return false;
          },
        );
      }
    }
  }

  void _executeMeleeCrush() {
    if (_isPerformingAttack) return;
    _isPerformingAttack = true;
    idle(); // Stop moving to charge

    // Melee crush windup: flash purple, shake slightly
    add(
      ColorEffect(
        const Color(0xFF9C27B0),
        EffectController(duration: 0.25, reverseDuration: 0.15),
      ),
    );
    GameFeel.triggerScreenShake(this, duration: 0.2, intensity: 3.0);

    // Crush strike delay (400ms)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (isDead) return;
      SoundService.play('punch.wav');
      simpleAttackMelee(
        damage: damage * 1.5,
        size: Vector2(80, 80),
        withPush: true,
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        _isPerformingAttack = false;
      });
    });
  }

  void _executeRadialAttack() {
    if (isDead) return;
    _isPerformingAttack = true;
    idle(); // Stop moving to channel attack

    // Charge indicators: Heavy flash and screen shake!
    add(
      ColorEffect(
        const Color(0xFFFF0055),
        EffectController(duration: 0.3, reverseDuration: 0.3),
      ),
    );
    GameFeel.triggerScreenShake(this, duration: 0.6, intensity: 5.0);

    // Telegraph shoot delay (600ms channeling)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isDead) return;
      SoundService.play('shoot.wav');

      const int bulletCount = 8;
      for (int i = 0; i < bulletCount; i++) {
        final double angle = (i * 2 * pi) / bulletCount;
        simpleAttackRangeByAngle(
          angle: angle,
          damage: damage * 0.8,
          size: Vector2(8, 8),
          speed: 160.0,
          attackFrom: AttackOriginEnum.ENEMY,
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
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        _isPerformingAttack = false;
      });
    });
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    if (isDead) return;

    SoundService.play('hit.wav');
    // Draw critiques for heavy boss strikes!
    final bool isCrit = damage >= 25.0;
    spawnDamageText(damage, isCrit: isCrit, color: isCrit ? Colors.amberAccent : Colors.redAccent);

    // Boss has high mass, low knockback push-back
    final attackerPos = (identify is GameComponent) ? identify.position.x : position.x - 20;
    final fromLeft = attackerPos < position.x;
    applyKnockback(60.0, fromLeft);

    super.onReceiveDamage(attacker, damage, identify);
  }

  @override
  void onDie() {
    SoundService.play('death.wav');
    GameFeel.triggerScreenShake(this, duration: 0.8, intensity: 8.0);
    super.onDie();
    final rand = Random();
    if (rand.nextDouble() < 0.3) {
      final type = PickupType.values[rand.nextInt(PickupType.values.length)];
      gameRef.add(
        PickupComponent(
          position: center - Vector2(10, 10),
          type: type,
        ),
      );
    }
  }
}
