import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class GamesServicesWrapper {
  static bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Authenticates the player with the native games service.
  static Future<void> signIn() async {
    if (!_isSupported) return;
    try {
      await GamesServices.signIn();
    } catch (e) {
      debugPrint('GamesServices sign in failed: $e');
    }
  }

  /// Submits a high score to a leaderboard.
  static Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    if (!_isSupported) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: leaderboardId,
          iOSLeaderboardID: leaderboardId,
          value: score,
        ),
      );
    } catch (e) {
      debugPrint('GamesServices submitScore failed: $e');
    }
  }

  /// Unlocks an achievement.
  static Future<void> unlockAchievement({required String achievementId}) async {
    if (!_isSupported) return;
    try {
      await GamesServices.unlock(
        achievement: Achievement(
          androidID: achievementId,
          iOSID: achievementId,
        ),
      );
    } catch (e) {
      debugPrint('GamesServices unlockAchievement failed: $e');
    }
  }

  /// Shows the platform achievements screen.
  static Future<void> showAchievements() async {
    if (!_isSupported) return;
    try {
      await GamesServices.showAchievements();
    } catch (e) {
      debugPrint('GamesServices showAchievements failed: $e');
    }
  }

  /// Shows the platform leaderboards screen.
  static Future<void> showLeaderboards({required String leaderboardId}) async {
    if (!_isSupported) return;
    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: leaderboardId,
        androidLeaderboardID: leaderboardId,
      );
    } catch (e) {
      debugPrint('GamesServices showLeaderboards failed: $e');
    }
  }
}
