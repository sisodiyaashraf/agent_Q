import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:flutter/material.dart';
import '../hub_screen.dart';

class GameSplashScreen extends StatelessWidget {
  const GameSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_images/Splashscreenar.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FlameSplashScreen(
          theme: FlameSplashTheme.dark,
          showBefore: (context) {
            return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AGENT Q',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TACTICAL SHOOTER INITIATED',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          );
        },
        onFinish: (context) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HubScreen()),
          );
        },
      ),
    ),
    );
  }
}
