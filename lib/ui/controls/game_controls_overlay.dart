import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../../game/player/agent_q_component.dart';

class GameControlsOverlay extends StatelessWidget {
  final BonfireGame game;

  const GameControlsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final player = game.player;
    if (player == null || player.isDead || player is! AgentQComponent) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Jump Button (top center of the cluster)
              _buildActionButton(
                label: 'JUMP',
                icon: Icons.arrow_upward,
                color: Colors.white24,
                onPressed: player.jump,
                size: 54,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Punch Button
                  _buildActionButton(
                    label: 'PUNCH',
                    icon: Icons.sports_martial_arts,
                    color: Colors.white24,
                    onPressed: player.punch,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  // Dash Button (Dodge maneuver)
                  _buildActionButton(
                    label: 'DASH',
                    icon: Icons.bolt,
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    borderColor: const Color(0xFF00E5FF),
                    onPressed: player.dash,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  // Shoot Button (Primary Action - highlighted)
                  _buildActionButton(
                    label: 'SHOOT',
                    icon: Icons.adjust,
                    color: const Color(0xFFFF3D00).withValues(alpha: 0.3),
                    borderColor: const Color(0xFFFF3D00),
                    onPressed: player.shoot,
                    size: 64,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double size,
    Color borderColor = Colors.white30,
  }) {
    return Listener(
      onPointerDown: (_) => onPressed(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: size * 0.4),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
