import 'package:bonfire/bonfire.dart';

class MaskedEliteEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

  MaskedEliteEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(32, 32),
          life: health * 1.6, // Sturdy elite health
          speed: speed * 1.15, // Fast speed
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_masked_elite.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.2,
                textureSize: Vector2(32, 32),
                texturePosition: Vector2(0, 0),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_masked_elite.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.12,
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
        size: Vector2(22, 26),
        position: Vector2(5, 3),
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
}
