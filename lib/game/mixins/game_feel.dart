import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:bonfire/mixins/direction_animation.dart';
import 'package:flutter/material.dart';
import '../../services/sound_service.dart';

class GameFeel {
  static double hitStopTimer = 0.0;

  static void triggerHitStop(double duration) {
    hitStopTimer = duration;
  }

  static void update(double dt) {
    if (hitStopTimer > 0) {
      hitStopTimer -= dt;
    }
  }

  static void triggerScreenShake(GameComponent component, {double duration = 0.15, double intensity = 4.0}) {
    try {
      component.gameRef.camera.shake(
        intensity: intensity,
        duration: Duration(milliseconds: (duration * 1000).toInt()),
      );
    } catch (_) {}
  }
}

mixin GameFeelMixin on Movement, DirectionAnimation {
  double knockbackX = 0.0;

  void applyKnockback(double amount, bool fromLeft) {
    knockbackX = fromLeft ? amount : -amount;
  }

  void updateKnockback(double dt) {
    if (knockbackX.abs() > 0.1) {
      position.x += knockbackX * dt;
      // Decelerate knockback quickly (friction multiplier 12.0)
      knockbackX += (0.0 - knockbackX) * (1.0 - exp(-12.0 * dt));
    } else {
      knockbackX = 0.0;
    }
  }

  void spawnDamageText(double damage, {bool isCrit = false, Color? color}) {
    if (!hasGameRef) return;
    final textPos = Vector2(
      position.x + size.x / 2 - 10 + (Random().nextDouble() * 20 - 10),
      position.y - 15,
    );
    final String text = isCrit ? '${damage.round()}! CRIT' : '${damage.round()}';
    final Color textColor = color ?? (isCrit ? Colors.orangeAccent : Colors.redAccent);
    
    gameRef.add(
      FloatingTextComponent(
        position: textPos,
        text: text,
        color: textColor,
      ),
    );
  }

  void playDeathAnimationAndRemove(String spritePath) {
    if (!hasGameRef) return;

    SoundService.play('death.wav');

    // Fade-out effect during the death animation sequence
    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.36),
      ),
    );

    final image = Flame.images.fromCache(spritePath);
    final sheet = SpriteSheet(
      image: image,
      srcSize: Vector2(677 / 6, 369 / 3),
    );

    final dieAnim = SpriteAnimation.variableSpriteList([
      sheet.getSprite(2, 0),
      sheet.getSprite(2, 1),
      sheet.getSprite(2, 2),
    ], stepTimes: [0.12, 0.12, 0.12]);

    animation?.playOnce(
      dieAnim,
      flipX: lastDirection == Direction.left,
      onFinish: () {
        removeFromParent();
      },
    );
  }
}

class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color color;
  double _lifeTime = 0.55;

  FloatingTextComponent({
    required super.position,
    required this.text,
    required this.color,
  }) : super(size: Vector2(100, 30));

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 45 * dt;
    _lifeTime -= dt;
    if (_lifeTime <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double opacity = (_lifeTime / 0.55).clamp(0.0, 1.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'Courier',
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: opacity),
              offset: const Offset(1, 1),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset.zero);
  }
}
