import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../items/pickup_component.dart';

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
              Flame.images.fromCache('characters/soldier_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 4, 369),
                texturePosition: Vector2(2 * (677 / 4), 0),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/soldier_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677 / 4, 369),
                texturePosition: Vector2(2 * (677 / 4), 0),
              ),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    final soldierImage = Flame.images.fromCache('characters/soldier_enemy.png');
    final soldierSheet = SpriteSheet(
      image: soldierImage,
      srcSize: Vector2(677 / 4, 369),
    );

    animation = SimpleDirectionAnimation(
      idleRight: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 2, to: 3),
      runRight: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 2, to: 3),
      idleLeft: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 3, to: 4),
      runLeft: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 3, to: 4),
      idleUp: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 1, to: 2),
      runUp: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 1, to: 2),
      idleDown: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 0, to: 1),
      runDown: soldierSheet.createAnimation(row: 0, stepTime: 0.15, from: 0, to: 1),
    );

    add(
      RectangleHitbox(
        size: Vector2(20, 24),
        position: Vector2(6, 4),
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

    final isMoving = velocity.x != 0 || velocity.y != 0;
    if (isMoving) {
      _bobTimer += dt * 10;
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.06);
    } else {
      scale = Vector2.all(1.0);
    }

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
