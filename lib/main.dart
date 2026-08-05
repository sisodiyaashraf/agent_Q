import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/save_service.dart';
import 'ui/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences progression service
  await SaveService.init();

  // Force landscape orientation for optimal twin-stick play area
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set sticky immersive fullscreen mode to hide status bars
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AgentQApp());
}

class AgentQApp extends StatelessWidget {
  const AgentQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Q',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Courier', // Cybernetic styling font
        scaffoldBackgroundColor: const Color(0xFF060814),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0C0F24),
          elevation: 0,
        ),
      ),
      home: const GameSplashScreen(),
    );
  }
}
