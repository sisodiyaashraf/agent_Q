import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../../services/sound_service.dart';
import '../items/pickup_component.dart';
import '../mixins/game_feel.dart';
import 'enemy_health_bar.dart';

class AlienSmallEnemy extends SimpleEnemy with BlockMovementCollision, GameFeelMixin {
  final double damage;
  bool _isAttacking = false;
  double _bobTimer = 0.0;

  AlienSmallEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(72, 79), // Scaled size
          life: health * 0.6, // Low health
          speed: speed * 1.35, // Very fast
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Small_alien_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(4 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Small_alien_enemy.png'),
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
      image: Flame.images.fromCache('characters/Small_alien_enemy.png'),
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    animation = SimpleDirectionAnimation(
      enabledFlipX: true,
      idleRight: walkSheet.createAnimation(row: 1, stepTime: 0.12, from: 4, to: 5),
      runRight: SpriteAnimation.variableSpriteList([
        walkSheet.getSprite(1, 5),
        walkSheet.getSprite(2, 0),
        walkSheet.getSprite(2, 1),
        walkSheet.getSprite(2, 2),
        walkSheet.getSprite(2, 3),
        walkSheet.getSprite(2, 4),
        walkSheet.getSprite(2, 5),
      ], stepTimes: List.filled(7, 0.08)), // Fast running frames
    );

    add(
      RectangleHitbox(
        size: Vector2(36, 36),
        position: Vector2(18, 20),
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
      _bobTimer += dt * 13; // fast bobbing
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

    if (!_isAttacking && knockbackX == 0) {
      seeAndMoveToPlayer(
        closePlayer: (player) {
          _executeMeleeAttack();
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

  void _executeMeleeAttack() {
    if (_isAttacking) return;
    _isAttacking = true;
    idle(); // Stop moving to strike

    // Fast telegraph warning: flash cyan
    add(
      ColorEffect(
        const Color(0xFF00E5FF),
        EffectController(duration: 0.15, reverseDuration: 0.1),
      ),
    );

    // Bite animation windup (row 2 cols 0-2)
    final walkSheet = SpriteSheet(
      image: Flame.images.fromCache('characters/Small_alien_enemy.png'),
      srcSize: Vector2(677 / 6, 369 / 3),
    );
    final biteAnim = SpriteAnimation.variableSpriteList([
      walkSheet.getSprite(2, 0),
      walkSheet.getSprite(2, 1),
      walkSheet.getSprite(2, 2),
    ], stepTimes: [0.08, 0.08, 0.08]);
    animation?.playOnce(biteAnim, flipX: lastDirection == Direction.left);

    // Bite strike after 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isDead) return;
      simpleAttackMelee(
        damage: damage,
        size: Vector2(18, 18),
        withPush: true,
        execute: () {
          Future.delayed(const Duration(milliseconds: 400), () {
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

    // Physical knockback push-back (high knockback for small swarmers)
    final attackerPos = (identify is GameComponent) ? identify.position.x : position.x - 20;
    final fromLeft = attackerPos < position.x;
    applyKnockback(175.0, fromLeft);

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
