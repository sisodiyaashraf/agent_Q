import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../items/pickup_component.dart';

class AlienSmallEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

  AlienSmallEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(72, 79), // Scaled size
          life: health * 0.5, // Low health
          speed: speed * 1.4, // Very fast
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Small_alien_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(2 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Small_alien_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 6, 369 / 3),
                texturePosition: Vector2(3 * (677 / 6), 1 * (369 / 3)),
              ),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    final alienImage = Flame.images.fromCache('characters/Small_alien_enemy.png');
    final alienSheet = SpriteSheet(
      image: alienImage,
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    animation = SimpleDirectionAnimation(
      idleRight: alienSheet.createAnimation(row: 1, stepTime: 0.15, from: 2, to: 4),
      runRight: alienSheet.createAnimation(row: 1, stepTime: 0.15, from: 2, to: 4),
      idleUp: alienSheet.createAnimation(row: 0, stepTime: 0.15, from: 4, to: 6),
      runUp: alienSheet.createAnimation(row: 0, stepTime: 0.15, from: 4, to: 6),
      idleDown: alienSheet.createAnimation(row: 1, stepTime: 0.15, from: 0, to: 2),
      runDown: alienSheet.createAnimation(row: 1, stepTime: 0.15, from: 0, to: 2),
    );

    add(
      RectangleHitbox(
        size: Vector2(36, 36),
        position: Vector2(18, 20),
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
      _bobTimer += dt * 12;
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

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

  void _executeMeleeAttack() {
    if (_isAttacking) return;
    _isAttacking = true;

    simpleAttackMelee(
      damage: damage,
      size: Vector2(18, 18),
      withPush: true,
      execute: () {
        Future.delayed(const Duration(milliseconds: 600), () {
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
