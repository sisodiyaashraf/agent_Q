import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  static MusicService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();

  // Settings keys
  static const String _keyMusicVolume = 'agent_q_music_volume';
  static const String _keyMusicMuted = 'agent_q_music_muted';
  static const String _keySfxMuted = 'agent_q_sfx_muted';

  SharedPreferences? _prefs;
  double _volume = 0.5; // 0.0 to 1.0 (user-selected range)
  bool _isMuted = false;
  bool _sfxMuted = false;

  String? _currentTrack;
  String? _targetTrack; // Track we want to play (or are fading into)

  // Scaled max volume for background music to prevent drowning out SFX
  static const double _maxBgmVolumeScale = 0.3;

  Timer? _fadeTimer;

  /// Initializes the music service and loads saved settings.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _volume = _prefs?.getDouble(_keyMusicVolume) ?? 0.5;
      _isMuted = _prefs?.getBool(_keyMusicMuted) ?? false;
      _sfxMuted = _prefs?.getBool(_keySfxMuted) ?? false;

      await _player.setReleaseMode(ReleaseMode.loop);
      await _updatePlayerVolume();
    } catch (_) {
      // Fallback defaults if SharedPreferences initialization fails
    }
  }

  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get sfxMuted => _sfxMuted;
  String? get currentTrack => _currentTrack;

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _prefs?.setDouble(_keyMusicVolume, _volume);
    await _updatePlayerVolume();
  }

  Future<void> setMuted(bool val) async {
    _isMuted = val;
    await _prefs?.setBool(_keyMusicMuted, _isMuted);
    await _updatePlayerVolume();
  }

  Future<void> setSfxMuted(bool val) async {
    _sfxMuted = val;
    await _prefs?.setBool(_keySfxMuted, _sfxMuted);
  }

  Future<void> _updatePlayerVolume() async {
    if (_isMuted) {
      await _player.setVolume(0.0);
    } else {
      await _player.setVolume(_volume * _maxBgmVolumeScale);
    }
  }

  /// Returns the corresponding track file name for a given world ID.
  String getTrackForWorld(int worldId) {
    switch (worldId) {
      case 1:
        return 'world1_soldier.ogg';
      case 2:
        return 'world2_zombie.ogg';
      case 3:
        return 'world3_alien.ogg';
      case 4:
        return 'world4_elite.ogg';
      case 5:
        return 'world5_boss.ogg';
      default:
        return 'hub_theme.ogg';
    }
  }

  /// Smoothly transition to play the target track with fade-out and fade-in.
  /// If trackName is already playing/target, does nothing to avoid stacking audio.
  Future<void> play(String trackName) async {
    if (_targetTrack == trackName) return;
    _targetTrack = trackName;

    _fadeTimer?.cancel();

    // If nothing is playing or active, immediately play and fade-in
    if (_currentTrack == null || _player.state != PlayerState.playing) {
      _currentTrack = trackName;
      await _player.setVolume(0.0);
      try {
        await _player.play(AssetSource('audio/music/$trackName'));
      } catch (_) {}
      _fadeIn();
      return;
    }

    // Transition: Fade out, stop, switch track, play, fade in
    _fadeOut(() async {
      _currentTrack = trackName;
      await _player.stop();
      await _player.setVolume(0.0);
      try {
        await _player.play(AssetSource('audio/music/$trackName'));
      } catch (_) {}
      _fadeIn();
    });
  }

  void _fadeOut(void Function() onDone) {
    const int steps = 10;
    const Duration stepDuration = Duration(milliseconds: 50);
    int currentStep = 0;
    final double startVolume = _isMuted ? 0.0 : (_volume * _maxBgmVolumeScale);

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;
      final double currentVol = startVolume * (1.0 - progress);

      try {
        await _player.setVolume(currentVol);
      } catch (_) {}

      if (currentStep >= steps) {
        timer.cancel();
        onDone();
      }
    });
  }

  void _fadeIn() {
    const int steps = 10;
    const Duration stepDuration = Duration(milliseconds: 50);
    int currentStep = 0;
    final double targetVolume = _isMuted ? 0.0 : (_volume * _maxBgmVolumeScale);

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;
      final double currentVol = targetVolume * progress;

      try {
        await _player.setVolume(currentVol);
      } catch (_) {}

      if (currentStep >= steps) {
        timer.cancel();
        await _updatePlayerVolume();
      }
    });
  }

  /// Stops current music playback and resets targets.
  Future<void> stop() async {
    _targetTrack = null;
    _currentTrack = null;
    _fadeTimer?.cancel();
    await _player.stop();
  }
}
