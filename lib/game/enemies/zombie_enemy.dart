import 'package:bonfire/bonfire.dart';

class ZombieEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

  ZombieEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(32, 32),
          life: health,
          speed: speed * 0.65, // Zombies are slow
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_zombie.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.2,
                textureSize: Vector2(32, 32),
                texturePosition: Vector2(0, 0),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_zombie.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.15,
                textureSize: Vector2(32, 32),
                texturePosition: Vector2(0, 32),
              ),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
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
}
