import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

class EnemyHealthBar extends PositionComponent with ParentIsA<SimpleEnemy> {
  EnemyHealthBar() : super();

  @override
  Future<void> onLoad() async {
    // Position the health bar above the enemy's head, relative to their body size
    size = Vector2(parent.size.x * 0.8, 5);
    position = Vector2(parent.size.x * 0.1, -12); // float 12 pixels above head
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (parent.isDead) return;

    final double healthPercent = (parent.life / parent.maxLife).clamp(0.0, 1.0);
    if (healthPercent <= 0) return;

    // Draw background (black border/frame)
    final bgPaint = Paint()..color = Colors.black87;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Draw inner red fill
    final fillPaint = Paint()..color = Colors.redAccent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, (size.x - 2) * healthPercent, size.y - 2),
        const Radius.circular(1),
      ),
      fillPaint,
    );
  }
}
