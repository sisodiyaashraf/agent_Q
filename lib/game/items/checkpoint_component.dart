import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../../services/sound_service.dart';
import '../player/agent_q_component.dart';

class CheckpointState {
  static int? savedLevelId;
  static Vector2? savedPosition;

  static void clear() {
    savedLevelId = null;
    savedPosition = null;
  }
}

class CheckpointComponent extends GameDecoration with Sensor {
  final int levelId;
  bool _activated = false;

  CheckpointComponent({
    required super.position,
    required this.levelId,
  }) : super.withSprite(
          sprite: Sprite.load('pickups_and_powerups/shield_power_up.png'), // Station indicator
          size: Vector2(24, 30),
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(size: Vector2(24, 30)));
    await super.onLoad();
  }

  @override
  void onContact(GameComponent component) {
    if (component is AgentQComponent && !_activated) {
      _activated = true;
      CheckpointState.savedLevelId = levelId;
      CheckpointState.savedPosition = position.clone();

      SoundService.play('pickup.wav');

      // Flash green effect on contact
      add(
        ColorEffect(
          const Color(0xFF00FF00),
          EffectController(duration: 0.2, reverseDuration: 0.2),
        ),
      );

      // Spawn a floating text banner
      if (hasGameRef) {
        final text = TextComponent(
          text: 'CHECKPOINT SECURED',
          position: Vector2(position.x - 50, position.y - 25),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              fontFamily: 'Courier',
              shadows: [Shadow(color: Colors.black, blurRadius: 1, offset: Offset(1, 1))],
            ),
          ),
        );
        gameRef.add(text);
        
        // Float text up and fade
        text.add(
          MoveEffect.by(
            Vector2(0, -35),
            EffectController(duration: 0.8),
            onComplete: () => text.removeFromParent(),
          ),
        );
      }
    }
  }
}
