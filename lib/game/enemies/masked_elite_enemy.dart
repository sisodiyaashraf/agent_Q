import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../items/pickup_component.dart';
import 'enemy_health_bar.dart';

class MaskedEliteEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

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
                textureSize: Vector2(677, 369),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Masked_elite_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677, 369),
              ),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: Vector2(46, 80),
        position: Vector2(25, 20),
      ),
    );
    add(EnemyHealthBar());
    await super.onLoad();
  }

  double _bobTimer = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) {
      scale = Vector2.all(1.0);
      return;
    }

    // Constrain enemy Y position to floor
    position.y = WorldConfig.floorY - size.y;

    final isMoving = velocity.x != 0 || velocity.y != 0;
    if (isMoving) {
      _bobTimer += dt * 11;
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

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

  void _executeMacheteSlash() {
    if (_isAttacking) return;
    _isAttacking = true;

    // Fast swing speed, high damage
    simpleAttackMelee(
      damage: damage * 1.3,
      size: Vector2(28, 28),
      withPush: true,
      execute: () {
        Future.delayed(const Duration(milliseconds: 700), () {
          _isAttacking = false;
        });
      },
    );
  }

  @override
  void onDie() {
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
