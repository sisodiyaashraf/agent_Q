import 'package:bonfire/bonfire.dart';

class AlienSmallEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

  AlienSmallEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(24, 24), // Smaller size
          life: health * 0.5, // Low health
          speed: speed * 1.4, // Very fast
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_alien_small.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.15,
                textureSize: Vector2(32, 32),
                texturePosition: Vector2(0, 0),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_alien_small.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.1,
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
        size: Vector2(16, 16),
        position: Vector2(4, 4),
      ),
    );
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

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
}
