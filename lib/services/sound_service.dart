import 'package:audioplayers/audioplayers.dart';
import 'music_service.dart';

class SoundService {
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> play(String sfxName) async {
    if (MusicService.instance.sfxMuted) return;
    try {
      AudioPlayer? player = _players[sfxName];
      if (player == null) {
        player = AudioPlayer();
        _players[sfxName] = player;
      } else {
        await player.stop();
      }
      await player.play(AssetSource('audio/$sfxName'));
    } catch (_) {
      // Silent catch to prevent sound issues from interrupting gameplay
    }
  }
}
