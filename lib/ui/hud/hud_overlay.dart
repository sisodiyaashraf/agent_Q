import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final String levelName;
  final double hp;
  final double maxHp;
  final double shield;
  final double maxShield;
  final int ammo;
  final int maxAmmo;
  final bool isReloading;
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
    required this.shield,
    required this.maxShield,
    required this.ammo,
    required this.maxAmmo,
    required this.isReloading,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health & Ammo Controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Image.asset(
                          'assets/images/hud_and_ui_elements/Health_bar_frame.png',
                          width: 180,
                          height: 48,
                          fit: BoxFit.fill,
                        ),
                        Positioned(
                          left: 24,
                          top: 14,
                          width: 132,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: healthPercent,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                healthPercent > 0.3
                                    ? const Color(0xFF00E5FF)
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                        if (shield > 0)
                          Positioned(
                            left: 24,
                            top: 23,
                            width: 132 * (shield / maxShield).clamp(0.0, 1.0),
                            height: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          left: 26,
                          top: 30,
                          child: Text(
                            shield > 0 
                                ? 'HP: ${hp.toInt()}  SHIELD: ${shield.toInt()}' 
                                : 'HP: ${hp.toInt()}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121F).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/hud_and_ui_elements/Ammo_counter_icon.png',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isReloading ? 'RELOADING' : 'AMMO: $ammo/$maxAmmo',
                            style: TextStyle(
                              color: isReloading ? Colors.redAccent : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  icon: Image.asset(
                    'assets/images/hud_and_ui_elements/Pause_button_icon.png',
                    width: 32,
                    height: 32,
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
