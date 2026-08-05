import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  static const String _unlockedLevelKey = 'agent_q_unlocked_level';
  static const String _highScorePrefix = 'agent_q_highscore_';
  static const String _bestTimePrefix = 'agent_q_besttime_';

  static late SharedPreferences _prefs;

  /// Initializes the Shared Preferences instance.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Gets the highest level number unlocked (1-indexed). Defaults to 1.
  static int getUnlockedLevel() {
    return _prefs.getInt(_unlockedLevelKey) ?? 1;
  }

  /// Sets/unlocks a new level. Only increases the level count.
  static Future<void> unlockLevel(int level) async {
    final current = getUnlockedLevel();
    if (level > current) {
      await _prefs.setInt(_unlockedLevelKey, level);
    }
  }

  /// Resets progress back to level 1 and clears highscores.
  static Future<void> resetProgress() async {
    await _prefs.setInt(_unlockedLevelKey, 1);
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_highScorePrefix) || key.startsWith(_bestTimePrefix)) {
        await _prefs.remove(key);
      }
    }
  }

  /// Saves a high score for a specific level.
  static Future<void> saveHighScore(int level, int score) async {
    final key = '$_highScorePrefix$level';
    final existing = _prefs.getInt(key) ?? 0;
    if (score > existing) {
      await _prefs.setInt(key, score);
    }
  }

  /// Gets the high score for a specific level.
  static int getHighScore(int level) {
    return _prefs.getInt('$_highScorePrefix$level') ?? 0;
  }

  /// Saves the best completion time (in seconds) for a specific level.
  static Future<void> saveBestTime(int level, int seconds) async {
    final key = '$_bestTimePrefix$level';
    final existing = _prefs.getInt(key) ?? 999999;
    if (seconds < existing) {
      await _prefs.setInt(key, seconds);
    }
  }

  /// Gets the best completion time (in seconds) for a specific level.
  static int getBestTime(int level) {
    return _prefs.getInt('$_bestTimePrefix$level') ?? 0;
  }
}
