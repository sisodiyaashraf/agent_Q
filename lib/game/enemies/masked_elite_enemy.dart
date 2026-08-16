import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../../services/sound_service.dart';
import '../items/pickup_component.dart';
import '../mixins/game_feel.dart';
import 'enemy_health_bar.dart';

class MaskedEliteEnemy extends SimpleEnemy with BlockMovementCollision, GameFeelMixin {
  final double damage;
  bool _isAttacking = false;
  double _bobTimer = 0.0;

  MaskedEliteEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(96, 105),
          life: health * 1.6, // Sturdy elite health
          speed: speed * 1.15, // Fast speed
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Masked_elite_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(4 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Masked_elite_enemy.png'),
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
      image: Flame.images.fromCache('characters/Masked_elite_enemy.png'),
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
      ], stepTimes: List.filled(7, 0.11)),
    );

    add(
      RectangleHitbox(
        size: Vector2(46, 80),
        position: Vector2(25, 20),
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
      _bobTimer += dt * 11;
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

    if (!_isAttacking && knockbackX == 0) {
      seeAndMoveToPlayer(
        closePlayer: (player) {
          _executeMacheteSlash();
        },
        radiusVision: 500.0,
        observed: () {},
        notObserved: () {
          final player = gameRef.player;
          if (player != null && !player.isDead) {
            moveToPosition(player.position, speed: speed);
          }
          return false;
        },
      );
    }
  }

  void _executeMacheteSlash() {
    if (_isAttacking) return;
    _isAttacking = true;
    idle(); // Stop moving to charge slash

    // Telegraphed windup warning: flash bright orange
    add(
      ColorEffect(
        const Color(0xFFFF5722),
        EffectController(duration: 0.2, reverseDuration: 0.15),
      ),
    );

    // Play swing animation windup (row 2 cols 0-2)
    final walkSheet = SpriteSheet(
      image: Flame.images.fromCache('characters/Masked_elite_enemy.png'),
      srcSize: Vector2(677 / 6, 369 / 3),
    );
    final swingAnim = SpriteAnimation.variableSpriteList([
      walkSheet.getSprite(2, 0),
      walkSheet.getSprite(2, 1),
      walkSheet.getSprite(2, 2),
    ], stepTimes: [0.08, 0.08, 0.08]);
    animation?.playOnce(swingAnim, flipX: lastDirection == Direction.left);

    // Fast slash strike after 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isDead) return;
      SoundService.play('punch.wav');
      simpleAttackMelee(
        damage: damage * 1.3,
        size: Vector2(28, 28),
        withPush: true,
        execute: () {
          Future.delayed(const Duration(milliseconds: 600), () {
            _isAttacking = false;
          });
        },
      );
    });
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    if (isDead) return;

    SoundService.play('hit.wav');
    spawnDamageText(damage);

    // Physical knockback push-back
    final attackerPos = (identify is GameComponent) ? identify.position.x : position.x - 20;
    final fromLeft = attackerPos < position.x;
    applyKnockback(120.0, fromLeft);

    super.onReceiveDamage(attacker, damage, identify);
  }

  @override
  void onDie() {
    SoundService.play('death.wav');
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
