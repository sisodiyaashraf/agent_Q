import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final String levelName;
  final double hp;
  final double maxHp;
  final int currentWave;
  final int totalWaves;
  final int activeEnemies;
  final String timeString;
  final VoidCallback onPause;

  const HudOverlay({
    super.key,
    required this.levelName,
    required this.hp,
    required this.maxHp,
    required this.currentWave,
    required this.totalWaves,
    required this.activeEnemies,
    required this.timeString,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final healthPercent = (hp / maxHp).clamp(0.0, 1.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top HUD Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Health Bar (glowing tech look)
                Container(
                  width: 140,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'AGENT HP',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: healthPercent,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            healthPercent > 0.3
                                ? const Color(0xFF00E5FF)
                                : Colors.redAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sector Name / Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        levelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeString,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),

                // Pause Button
                IconButton(
                  icon: const Icon(
                    Icons.pause_circle_filled,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onPause,
                ),
              ],
            ),
            const Spacer(),

            // Bottom Wave / Enemy Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Wave Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.waves, color: Colors.amber, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'WAVE $currentWave / $totalWaves',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Enemies Remaining
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        activeEnemies > 0 ? 'ENEMIES: $activeEnemies' : 'SECURE',
                        style: TextStyle(
                          color: activeEnemies > 0 ? Colors.white : const Color(0xFF00E5FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
