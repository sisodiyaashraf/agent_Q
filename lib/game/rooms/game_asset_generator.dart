import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/world_config.dart';

class GameAssetGenerator {
  /// Generates a tileset containing a Floor (left 32x32) and a Wall (right 32x32).
  static Future<ui.Image> generateTileset(WorldDefinition world) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 64, 32));

    // Floor Tile (0, 0) to (32, 32)
    final floorPaint = Paint()..color = world.floorColor;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32), floorPaint);
    // Draw floor grid pattern
    final floorGridPaint = Paint()
      ..color = world.primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32), floorGridPaint);
    // Draw some subtle detailing (dots/cracks)
    final detailPaint = Paint()..color = world.primaryColor.withValues(alpha: 0.2);
    canvas.drawRect(const Rect.fromLTWH(8, 8, 2, 2), detailPaint);
    canvas.drawRect(const Rect.fromLTWH(20, 24, 2, 2), detailPaint);

    // Wall Tile (32, 0) to (64, 32)
    final wallPaint = Paint()..color = world.wallColor;
    canvas.drawRect(const Rect.fromLTWH(32, 0, 32, 32), wallPaint);
    // Wall highlights
    final wallHighPaint = Paint()
      ..color = world.primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(const Rect.fromLTWH(33, 1, 30, 30), wallHighPaint);
    // Inner wall detail (panel line/cross)
    final wallDetailPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(32, 16), const Offset(64, 16), wallDetailPaint);
    canvas.drawLine(const Offset(48, 0), const Offset(48, 32), wallDetailPaint);

    final picture = recorder.endRecording();
    return await picture.toImage(64, 32);
  }

  /// Generates a sprite sheet for the Player: 128x64 containing:
  /// Row 0 (0-32): 4 frames of idle (32x32)
  /// Row 1 (32-64): 4 frames of walking (32x32)
  static Future<ui.Image> generatePlayer() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 64));

    // Draw 4 idle frames (top row)
    for (int i = 0; i < 4; i++) {
      final double dx = i * 32.0;
      final double dy = 0.0;
      _drawAgentQFrame(canvas, dx, dy, isWalking: false, frame: i);
    }

    // Draw 4 walking frames (bottom row)
    for (int i = 0; i < 4; i++) {
      final double dx = i * 32.0;
      final double dy = 32.0;
      _drawAgentQFrame(canvas, dx, dy, isWalking: true, frame: i);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 64);
  }

  /// Generates a sprite sheet for enemies: 128x64 containing:
  /// Row 0 (0-32): 4 frames of idle (32x32)
  /// Row 1 (32-64): 4 frames of walking (32x32)
  static Future<ui.Image> generateEnemy(EnemyType type) async {
    final recorder = ui.PictureRecorder();
    // Special dimensions for Boss
    final int width = type == EnemyType.alienBoss ? 256 : 128;
    final int height = type == EnemyType.alienBoss ? 128 : 64;
    final int size = type == EnemyType.alienBoss ? 64 : 32;

    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    for (int i = 0; i < 4; i++) {
      final double dx = (i * size).toDouble();
      _drawEnemyFrame(canvas, dx, 0, type, isWalking: false, frame: i, size: size);
      _drawEnemyFrame(canvas, dx, size.toDouble(), type, isWalking: true, frame: i, size: size);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  /// Generates a projectile image: 16x16
  static Future<ui.Image> generateBullet() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 16, 16));

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(8, 8),
        8,
        [const Color(0xFFFFEB3B), const Color(0xFFFF5722)],
      );
    canvas.drawCircle(const Offset(8, 8), 6, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(16, 16);
  }

  /// Generates a punch impact star animation: 96x32 (3 frames of 32x32)
  static Future<ui.Image> generateImpactStar() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 96, 32));

    // Draw Frame 0: Small yellow star burst
    _drawStarBurst(canvas, 16, 16, radius: 6, points: 5, color: const Color(0xFFFFEB3B));

    // Draw Frame 1: Large orange-yellow star burst with sparkles
    _drawStarBurst(canvas, 48, 16, radius: 12, points: 8, color: const Color(0xFFFFC107));
    _drawSparkle(canvas, 48 - 8, 16 - 8, const Color(0xFFFF5722));
    _drawSparkle(canvas, 48 + 8, 16 + 8, const Color(0xFFFF5722));

    // Draw Frame 2: Fading small orange star burst
    _drawStarBurst(canvas, 80, 16, radius: 8, points: 6, color: const Color(0xFFFF5722));

    final picture = recorder.endRecording();
    return await picture.toImage(96, 32);
  }

  static void _drawStarBurst(Canvas canvas, double cx, double cy, {required double radius, required int points, required Color color}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final double angle = pi / points;
    for (int i = 0; i < 2 * points; i++) {
      final double r = (i % 2 == 0) ? radius : radius / 2;
      final double x = cx + r * cos(i * angle - pi / 2);
      final double y = cy + r * sin(i * angle - pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  static void _drawSparkle(Canvas canvas, double cx, double cy, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 2, paint);
  }

  // DRAW HELPERS FOR PLAYER
  static void _drawAgentQFrame(Canvas canvas, double ox, double oy, {required bool isWalking, required int frame}) {
    final double walkOffset = isWalking ? (frame % 2 == 0 ? 1.0 : -1.0) : 0.0;

    // Legs / Feet
    final feetPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(Offset(ox + 10, oy + 26 + walkOffset), 4, feetPaint);
    canvas.drawCircle(Offset(ox + 22, oy + 26 - walkOffset), 4, feetPaint);

    // Body (Agent Suit - Black/Grey)
    final suitPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRect(Rect.fromLTWH(ox + 8, oy + 10, 16, 14), suitPaint);

    // Shoulders / Arms holding gun
    final armPaint = Paint()..color = const Color(0xFF455A64);
    canvas.drawRect(Rect.fromLTWH(ox + 4, oy + 12 + walkOffset, 4, 8), armPaint);
    // Gun extending forward (right)
    final gunPaint = Paint()..color = const Color(0xFF78909C);
    canvas.drawRect(Rect.fromLTWH(ox + 20, oy + 14, 10, 4), gunPaint);

    // Head / Helmet (White with blue visor)
    final headPaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawCircle(Offset(ox + 16, oy + 10), 6, headPaint);
    final visorPaint = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawRect(Rect.fromLTWH(ox + 14, oy + 7, 7, 3), visorPaint);
  }

  // DRAW HELPERS FOR ENEMIES
  static void _drawEnemyFrame(Canvas canvas, double ox, double oy, EnemyType type, {required bool isWalking, required int frame, required int size}) {
    final double scale = size / 32.0;
    final center = Offset(ox + size / 2, oy + size / 2);
    final double animOffset = isWalking ? (frame % 2 == 0 ? 2.0 : -2.0) * scale : 0.0;

    switch (type) {
      case EnemyType.zombie:
        // Green decaying body
        final bodyPaint = Paint()..color = const Color(0xFF2E7D32);
        canvas.drawCircle(center, 10 * scale, bodyPaint);
        // Head
        final headPaint = Paint()..color = const Color(0xFF4CAF50);
        canvas.drawCircle(Offset(center.dx, center.dy - 6 * scale), 6 * scale, headPaint);
        // Red glowing eyes
        final eyePaint = Paint()..color = const Color(0xFFFF1744);
        canvas.drawCircle(Offset(center.dx + 3 * scale, center.dy - 7 * scale), 1.5 * scale, eyePaint);
        // Reaching arms
        final armPaint = Paint()..color = const Color(0xFF388E3C);
        canvas.drawRect(Rect.fromLTWH(ox + 20, oy + 12 + animOffset, 10, 4), armPaint);
        break;

      case EnemyType.soldier:
        // Desert camo/Brown gear
        final suitPaint = Paint()..color = const Color(0xFF5D4037);
        canvas.drawRect(Rect.fromLTWH(ox + 8 * scale, oy + 10 * scale, 16 * scale, 14 * scale), suitPaint);
        // Steel helmet
        final helmetPaint = Paint()..color = const Color(0xFF78909C);
        canvas.drawCircle(Offset(center.dx, center.dy - 6 * scale), 7 * scale, helmetPaint);
        // Gun
        final gunPaint = Paint()..color = const Color(0xFF263238);
        canvas.drawRect(Rect.fromLTWH(ox + 20 * scale, oy + 14 * scale + animOffset, 11 * scale, 3.5 * scale), gunPaint);
        break;

      case EnemyType.alienSmall:
        // Insect / Bug Swarmer (Purple body, sharp elements)
        final bodyPaint = Paint()..color = const Color(0xFF6A1B9A);
        final path = Path()
          ..moveTo(center.dx - 8 * scale, center.dy)
          ..lineTo(center.dx + 8 * scale, center.dy - 4 * scale)
          ..lineTo(center.dx + 12 * scale, center.dy)
          ..lineTo(center.dx + 8 * scale, center.dy + 4 * scale)
          ..close();
        canvas.drawPath(path, bodyPaint);
        // Glowing yellow eyes
        final eyePaint = Paint()..color = const Color(0xFFFFEB3B);
        canvas.drawCircle(Offset(center.dx + 8 * scale, center.dy - 2 * scale), 1.5 * scale, eyePaint);
        // Tiny bug legs
        final legPaint = Paint()
          ..color = const Color(0xFF4A148C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale;
        canvas.drawLine(Offset(center.dx, center.dy), Offset(center.dx - 6 * scale, center.dy + 8 * scale + animOffset), legPaint);
        canvas.drawLine(Offset(center.dx, center.dy), Offset(center.dx + 6 * scale, center.dy + 8 * scale - animOffset), legPaint);
        break;

      case EnemyType.maskedElite:
        // Melee elite (Dark cloak, stark white mask)
        final cloakPaint = Paint()..color = const Color(0xFF1A1A1A);
        canvas.drawCircle(center, 11 * scale, cloakPaint);
        // White mask face
        final maskPaint = Paint()..color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(ox + 16 * scale, oy + 8 * scale, 8 * scale, 12 * scale), maskPaint);
        // Black hollow eyes on mask
        final eyePaint = Paint()..color = Colors.black;
        canvas.drawCircle(Offset(ox + 20 * scale, oy + 12 * scale), 1.5 * scale, eyePaint);
        canvas.drawCircle(Offset(ox + 20 * scale, oy + 16 * scale), 1.5 * scale, eyePaint);
        // Machete weapon
        final swordPaint = Paint()..color = const Color(0xFFB0BEC5);
        canvas.drawLine(Offset(ox + 22 * scale, oy + 16 * scale), Offset(ox + 30 * scale, oy + 4 * scale + animOffset), swordPaint);
        break;

      case EnemyType.alienBoss:
        // Giant alien mothership/hive beast (Dark purple/violet with multiple glowing spots)
        final bodyPaint = Paint()..color = const Color(0xFF120024);
        canvas.drawCircle(center, 24 * scale, bodyPaint);
        // Plated armor on top
        final armorPaint = Paint()..color = const Color(0xFF3B0066);
        canvas.drawCircle(center, 18 * scale, armorPaint);
        // Glow crystals/eyes
        final glowPaint = Paint()..color = const Color(0xFFFF0055);
        canvas.drawCircle(Offset(center.dx + 12 * scale, center.dy - 12 * scale + animOffset), 4 * scale, glowPaint);
        canvas.drawCircle(Offset(center.dx + 12 * scale, center.dy + 12 * scale - animOffset), 4 * scale, glowPaint);
        canvas.drawCircle(Offset(center.dx + 20 * scale, center.dy), 3 * scale, glowPaint);
        // Mandibles / spikes
        final spikePaint = Paint()..color = const Color(0xFF0D001A);
        final spikePath = Path()
          ..moveTo(center.dx + 16 * scale, center.dy - 12 * scale)
          ..lineTo(center.dx + 30 * scale, center.dy - 18 * scale + animOffset)
          ..lineTo(center.dx + 20 * scale, center.dy - 4 * scale)
          ..moveTo(center.dx + 16 * scale, center.dy + 12 * scale)
          ..lineTo(center.dx + 30 * scale, center.dy + 18 * scale - animOffset)
          ..lineTo(center.dx + 20 * scale, center.dy + 4 * scale);
        canvas.drawPath(spikePath, spikePaint);
        break;
    }
  }
}
