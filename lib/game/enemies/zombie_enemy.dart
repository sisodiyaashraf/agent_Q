import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../../services/sound_service.dart';
import '../items/pickup_component.dart';
import '../mixins/game_feel.dart';
import 'enemy_health_bar.dart';

class ZombieEnemy extends SimpleEnemy with BlockMovementCollision, GameFeelMixin {
  final double damage;
  bool _isAttacking = false;
  double _bobTimer = 0.0;

  ZombieEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(96, 105),
          life: health,
          speed: speed * 0.65, // Zombies are slow
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Zombie_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(4 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Zombie_enemy.png'),
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
      image: Flame.images.fromCache('characters/Zombie_enemy.png'),
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
      ], stepTimes: List.filled(7, 0.12)),
    );

    add(
      RectangleHitbox(
        size: Vector2(40, 85),
        position: Vector2(28, 20),
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

    // Apply knockback physics
    updateKnockback(dt);

    final isMoving = velocity.x != 0 || velocity.y != 0;
    if (isMoving && knockbackX == 0) {
      _bobTimer += dt * 10;
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

    if (!_isAttacking && knockbackX == 0) {
      // Pursue player across the entire room (arena mode)
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
    idle(); // Stop moving to charge punch

    // Telegraphed windup warning: flash yellow/orange
    add(
      ColorEffect(
        const Color(0xFFFF9800),
        EffectController(duration: 0.25, reverseDuration: 0.15),
      ),
    );

    // Punch animation windup (using row 2 frames 0-2)
    final walkSheet = SpriteSheet(
      image: Flame.images.fromCache('characters/Zombie_enemy.png'),
      srcSize: Vector2(677 / 6, 369 / 3),
    );
    final punchAnim = SpriteAnimation.variableSpriteList([
      walkSheet.getSprite(2, 0),
      walkSheet.getSprite(2, 1),
      walkSheet.getSprite(2, 2),
    ], stepTimes: [0.1, 0.1, 0.1]);
    animation?.playOnce(punchAnim, flipX: lastDirection == Direction.left);

    // Strike after a 400ms telegraphed charge time
    Future.delayed(const Duration(milliseconds: 400), () {
      if (isDead) return;
      simpleAttackMelee(
        damage: damage,
        size: Vector2(24, 24),
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
    applyKnockback(150.0, fromLeft);

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
