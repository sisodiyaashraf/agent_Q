import 'dart:async' as async;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import '../core/constants/world_config.dart';
import '../services/save_service.dart';
import '../services/games_services_wrapper.dart';
import '../ui/hud/hud_overlay.dart';
import '../ui/controls/game_controls_overlay.dart';
import 'player/agent_q_component.dart';
import 'rooms/game_asset_generator.dart';
import 'rooms/room_definition.dart';
import 'rooms/wave_manager.dart';

class AgentQGameWidget extends StatefulWidget {
  final int levelId;

  const AgentQGameWidget({super.key, required this.levelId});

  @override
  State<AgentQGameWidget> createState() => _AgentQGameWidgetState();
}

class _AgentQGameWidgetState extends State<AgentQGameWidget> {
  bool _loading = true;
  double _playerHp = AgentQComponent.maxHealth;
  double _playerMaxHp = AgentQComponent.maxHealth;
  double _playerShield = 0.0;
  double _playerMaxShield = 50.0;
  int _playerAmmo = 30;
  int _playerMaxAmmo = 30;
  bool _playerReloading = false;

  int _currentWave = 0;
  int _totalWaves = 0;
  int _activeEnemies = 0;
  bool _levelWon = false;
  bool _gameOver = false;

  late RoomDefinition _roomDef;
  final _stopwatch = Stopwatch();
  async.Timer? _timer;
  String _timeString = '00:00';

  final _fireworksController = FireworksController(
    colors: [
      const Color(0xFF00E5FF),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ],
    minExplosionDuration: 1.0,
    maxExplosionDuration: 2.5,
    minParticleCount: 80,
    maxParticleCount: 150,
  );

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getBackgroundPath(int worldId) {
    switch (worldId) {
      case 1:
        return 'background_images/AbandonedtownZombieworl.jpeg';
      case 2:
        return 'background_images/UrbanoutskirtsSoldierworl.jpeg';
      case 3:
        return 'background_images/ResearchfacilityAlienworldsmal.jpeg';
      case 4:
        return 'background_images/DeepfacilityElitemasked-enemyworl.jpeg';
      case 5:
      default:
        return 'background_images/Aliencorezonefinalworl.jpeg';
    }
  }

  Future<void> _initGame() async {
    _roomDef = RoomDefinition.generate(widget.levelId);

    // Dynamic generation of tileset & caching in Flame
    final world = _roomDef.world;
    final tilesetImg = await GameAssetGenerator.generateTileset(world);
    final bulletImg = await GameAssetGenerator.generateBullet();

    Flame.images.add('tileset.png', tilesetImg);
    Flame.images.add('bullet.png', bulletImg);

    // Load real images from assets/images/
    await Flame.images.load('characters/walk_cycle_agent_Q.png');
    await Flame.images.load('characters/Shooting_animation_aq.png');
    await Flame.images.load('characters/Zombie_enemy.png');
    await Flame.images.load('characters/soldier_enemy.png');
    await Flame.images.load('characters/Small_alien_enemy.png');
    await Flame.images.load('characters/Boss_alien_enemy.png');
    await Flame.images.load('characters/Masked_elite_enemy.png');

    final isZombieWorld = _roomDef.world.id == 1;
    if (isZombieWorld) {
      await Flame.images.load(
        'background_images/deep_facility_world/deep_facility_world.png',
      );
    } else {
      final bgPath = _getBackgroundPath(_roomDef.world.id);
      await Flame.images.load(bgPath);
    }

    _stopwatch.start();
    _timer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_levelWon || _gameOver) return;
      final sec = _stopwatch.elapsed.inSeconds;
      final minutes = (sec ~/ 60).toString().padLeft(2, '0');
      final seconds = (sec % 60).toString().padLeft(2, '0');
      setState(() => _timeString = '$minutes:$seconds');
    });

    setState(() => _loading = false);
  }

  void _onWaveStatusChanged(int current, int total, int active) {
    if (_levelWon || _gameOver) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentWave = current;
          _totalWaves = total;
          _activeEnemies = active;
        });
      }
    });
  }

  void _winLevel() {
    if (_levelWon) return;
    _stopwatch.stop();
    _timer?.cancel();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _levelWon = true);
        }
      });
    }

    final seconds = _stopwatch.elapsed.inSeconds;
    SaveService.unlockLevel(widget.levelId + 1);
    SaveService.saveHighScore(widget.levelId, 1000 - seconds * 2);
    SaveService.saveBestTime(widget.levelId, seconds);

    GamesServicesWrapper.submitScore(
      leaderboardId: 'agent_q_leaderboard_level_${widget.levelId}',
      score: 1000 - seconds * 2,
    );
    if (widget.levelId == 10 || widget.levelId == 50) {
      GamesServicesWrapper.unlockAchievement(
        achievementId: 'agent_q_achievement_milestone_${widget.levelId}',
      );
    }

    _fireworksController.fireMultipleRockets(
      minRockets: 6,
      maxRockets: 12,
      launchWindow: const Duration(milliseconds: 300),
    );
  }

  void _onPlayerHealthChanged(
    double current,
    double max,
    double shield,
    double maxShield,
  ) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _playerHp = current;
          _playerMaxHp = max;
          _playerShield = shield;
          _playerMaxShield = maxShield;
        });
      }
    });
  }

  void _onPlayerAmmoChanged(int current, int max, bool reloading) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _playerAmmo = current;
          _playerMaxAmmo = max;
          _playerReloading = reloading;
        });
      }
    });
  }

  void _onPlayerDeath() {
    _stopwatch.stop();
    _timer?.cancel();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _gameOver = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07090F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    final isZombieWorld = _roomDef.world.id == 1;
    final double screenHeight = MediaQuery.of(context).size.height;
    // Viewport/Scale Reconciliation Decision:
    // We selected Option A: Keep internal viewport height at 576px (WorldConfig.gameHeight = 576.0)
    // and draw characters at standard 96x105px size on-screen. This correctly places the character height
    // at ~18.2% of the screen height, matching the visual proportion of the reference video exactly.
    final double calculatedZoom = isZombieWorld
        ? (screenHeight > 0 ? screenHeight / WorldConfig.gameHeight : 1.0)
        : 1.5;

    final joystick = Joystick(
      directional: JoystickDirectional(
        spriteBackgroundDirectional: Sprite.load(
          'hud_and_ui_elements/virtual_joystick_base_and_knob.png',
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(368, 368),
        ),
        spriteKnobDirectional: Sprite.load(
          'hud_and_ui_elements/virtual_joystick_base_and_knob.png',
          srcPosition: Vector2(369, 0),
          srcSize: Vector2(307, 368),
        ),
        size: 80,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: Stack(
        children: [
          BonfireWidget(
            map: _roomDef.map,
            background: isZombieWorld
                ? null
                : RoomBackground(
                    path: _getBackgroundPath(_roomDef.world.id),
                    mapSize: Vector2(
                      _roomDef.gridWidth * _roomDef.tileSize,
                      _roomDef.gridHeight * _roomDef.tileSize,
                    ),
                  ),
            player: AgentQComponent(
              position: _roomDef.playerSpawn,
              onHealthChanged: _onPlayerHealthChanged,
              onAmmoChanged: _onPlayerAmmoChanged,
              onDeath: _onPlayerDeath,
            ),
            playerControllers: [joystick, Keyboard()],
            components: [
              if (isZombieWorld) LoopedFacilityBackground(),
              WaveManagerComponent(
                room: _roomDef,
                onAllWavesCleared: _winLevel,
                onWaveStatusChanged: _onWaveStatusChanged,
              ),
            ],
            cameraConfig: CameraConfig(
              moveOnlyMapArea: true,
              zoom: calculatedZoom,
            ),
            overlayBuilderMap: {
              'hud': (context, game) => HudOverlay(
                levelName: 'STAGE ${widget.levelId}',
                hp: _playerHp,
                maxHp: _playerMaxHp,
                shield: _playerShield,
                maxShield: _playerMaxShield,
                ammo: _playerAmmo,
                maxAmmo: _playerMaxAmmo,
                isReloading: _playerReloading,
                currentWave: _currentWave,
                totalWaves: _totalWaves,
                activeEnemies: _activeEnemies,
                timeString: _timeString,
                onPause: () {
                  game.pause();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => _buildPauseDialog(game),
                  );
                },
              ),
              'controls': (context, game) => GameControlsOverlay(game: game),
            },
            initialActiveOverlays: const ['hud', 'controls'],
          ),
          if (_levelWon) ...[
            IgnorePointer(
              child: FireworksDisplay(controller: _fireworksController),
            ),
            _buildCompletionOverlay(),
          ],
          if (_gameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildPauseDialog(BonfireGame game) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F121F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'PAUSED',
        style: TextStyle(color: Colors.white, letterSpacing: 2),
      ),
      content: const Text(
        'Resume combat or return to Sector map?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () {
            game.resume();
            Navigator.pop(context);
          },
          child: const Text(
            'RESUME',
            style: TextStyle(color: Color(0xFF00E5FF)),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text(
            'RETREAT',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                WorldConfig.isBossLevel(widget.levelId)
                    ? 'assets/images/achievements_and_progression/world_complete_badge.png'
                    : 'assets/images/achievements_and_progression/Level_Complete_banner.png',
                width: 200,
                height: 110,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'SECTOR SECURED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clear Time: $_timeString',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'PROCEED TO HUB',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C0D12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'AGENT DOWN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mission failed. Target eliminated player.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ABANDON',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AgentQGameWidget(levelId: widget.levelId),
                        ),
                      );
                    },
                    child: const Text(
                      'TRY AGAIN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomBackground extends GameBackground {
  final String path;
  final Vector2 mapSize;
  Sprite? _sprite;

  RoomBackground({required this.path, required this.mapSize});

  @override
  Future<void> onLoad() async {
    _sprite = await Sprite.load(path);
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      _sprite!.render(canvas, position: Vector2.zero(), size: mapSize);
    }
  }
}

class LoopedFacilityBackground extends GameBackground {
  Sprite? _sprite;
  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;

  LoopedFacilityBackground() : super();

  @override
  Future<void> onLoad() async {
    _sprite = await Sprite.load(
      'background_images/deep_facility_world/deep_facility_world.png',
    );
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (_sprite == null) return;

    final visibleRect = gameRef.camera.visibleWorldRect;
    final double scaledWidth = visibleRect.height * (2097 / 750);
    final double mapWidth = gameRef.map.size.x;
    final int repeats = (mapWidth / scaledWidth).ceil() + 2;

    for (int i = 0; i < repeats; i++) {
      // Use a tiny 1-pixel width overlap to prevent thin flickering seams between tiled repeats
      _sprite!.render(
        canvas,
        position: Vector2(i * scaledWidth, visibleRect.top),
        size: Vector2(scaledWidth + 1.0, visibleRect.height),
        overridePaint: _paint,
      );
    }
  }
}
