import 'dart:math';
import 'package:bonfire/bonfire.dart';

class SoldierEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  bool _isAttacking = false;

  SoldierEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(32, 32),
          life: health,
          speed: speed * 0.8, // Soldiers move at decent speed
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_soldier.png'),
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.2,
                textureSize: Vector2(32, 32),
                texturePosition: Vector2(0, 0),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('enemy_soldier.png'),
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

    seeAndMoveToAttackRange(
      minDistanceFromPlayer: 120.0, // Shoot from a distance
      radiusVision: 500.0,
      positioned: (player) {
        _executeRangedAttack(player);
      },
    );
  }

  void _executeRangedAttack(Player player) {
    if (_isAttacking) return;
    _isAttacking = true;

    final playerCenter = player.center;
    final enemyCenter = center;
    final angle = atan2(playerCenter.y - enemyCenter.y, playerCenter.x - enemyCenter.x);

    simpleAttackRangeByAngle(
      angle: angle,
      damage: damage,
      size: Vector2(6, 6),
      speed: 200.0,
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

    Future.delayed(const Duration(milliseconds: 1400), () {
      _isAttacking = false;
    });
  }
}
