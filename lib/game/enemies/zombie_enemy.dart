import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../items/pickup_component.dart';

class ZombieEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

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
                textureSize: Vector2(677, 369),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Zombie_enemy.png'),
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
        size: Vector2(40, 85),
        position: Vector2(28, 20),
      ),
    );
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
      _bobTimer += dt * 10;
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

    // Pursue player across the entire room (arena mode)
    seeAndMoveToPlayer(
      closePlayer: (player) {
        _executeMeleeAttack();
      },
      radiusVision: 500.0, // High radius to ensure they always chase the player
      observed: () {},
      notObserved: () {
        // Fallback: move towards player center directly if vision fails
        final player = gameRef.player;
        if (player != null && !player.isDead) {
          moveToPosition(player.position, speed: speed);
        }
        return false;
      },
    );
  }

  void _executeMeleeAttack() {
    if (_isAttacking) return;
    _isAttacking = true;

    simpleAttackMelee(
      damage: damage,
      size: Vector2(24, 24),
      withPush: true,
      execute: () {
        Future.delayed(const Duration(milliseconds: 1000), () {
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
