import 'dart:math';
import 'package:bonfire/bonfire.dart';
import '../../core/constants/world_config.dart';
import '../items/pickup_component.dart';

class AlienBossEnemy extends SimpleEnemy with BlockMovementCollision {
  final double damage;
  double _actionTimer = 3.0;
  bool _isPerformingAttack = false;

  AlienBossEnemy({
    required super.position,
    required double health,
    required double speed,
    required this.damage,
  }) : super(
          size: Vector2(192, 210), // Double standard size
          life: health * 3.5, // Boss tier health pool
          speed: speed * 0.5, // Slow boss movement
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Boss_alien_enemy.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1.0,
                textureSize: Vector2(677, 369),
              ),
            ),
            runRight: SpriteAnimation.fromFrameData(
              Flame.images.fromCache('characters/Boss_alien_enemy.png'),
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
        size: Vector2(144, 144),
        position: Vector2(24, 30),
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
      _bobTimer += dt * 8; // Boss is slower, slower bob
      scale = Vector2(1.0, 1.0 + sin(_bobTimer) * 0.05);
    } else {
      scale = Vector2.all(1.0);
    }

    _actionTimer -= dt;
    if (_actionTimer <= 0) {
      _executeRadialAttack();
      _actionTimer = 4.0; // Cooldown between boss special attacks
    }

    if (!_isPerformingAttack) {
      // Basic follow behavior
      final player = gameRef.player;
      if (player != null && !player.isDead) {
        seeAndMoveToPlayer(
          closePlayer: (p) {
            // Melee crush on contact
            _executeMeleeCrush();
          },
          radiusVision: 600.0,
          observed: () {},
          notObserved: () {
            moveToPosition(player.position, speed: speed);
            return false;
          },
        );
      }
    }
  }

  void _executeMeleeCrush() {
    simpleAttackMelee(
      damage: damage * 1.5,
      size: Vector2(72, 72),
      withPush: true,
    );
  }

  void _executeRadialAttack() {
    if (isDead) return;
    _isPerformingAttack = true;
    idle(); // Stop moving to channel attack

    // Shoot 8 bullets in a full circle ring
    const int bulletCount = 8;
    for (int i = 0; i < bulletCount; i++) {
      final double angle = (i * 2 * pi) / bulletCount;
      simpleAttackRangeByAngle(
        angle: angle,
        damage: damage * 0.8,
        size: Vector2(8, 8),
        speed: 150.0,
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
    }

    // Resume movement after attack animation finish
    Future.delayed(const Duration(milliseconds: 1000), () {
      _isPerformingAttack = false;
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
