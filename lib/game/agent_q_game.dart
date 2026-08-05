import 'dart:async' as async;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import '../core/constants/world_config.dart';
import '../services/save_service.dart';
import '../services/games_services_wrapper.dart';
import '../ui/hud/hud_overlay.dart';
import 'player/agent_q_component.dart';
import 'rooms/game_asset_generator.dart';
import 'rooms/room_definition.dart';
import 'rooms/wave_manager.dart';

class AgentQGameWidget extends StatefulWidget {
  final int levelId;

  const AgentQGameWidget({
    super.key,
    required this.levelId,
  });

  @override
  State<AgentQGameWidget> createState() => _AgentQGameWidgetState();
}

class _AgentQGameWidgetState extends State<AgentQGameWidget> {
  bool _loading = true;
  double _playerHp = AgentQComponent.maxHealth;
  double _playerMaxHp = AgentQComponent.maxHealth;
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
    colors: [const Color(0xFF00E5FF), const Color(0xFFFF9800), const Color(0xFFE91E63)],
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

  Future<void> _initGame() async {
    _roomDef = RoomDefinition.generate(widget.levelId);

    // Dynamic generation of assets & caching in Flame
    final world = _roomDef.world;
    final tilesetImg = await GameAssetGenerator.generateTileset(world);
    final playerImg = await GameAssetGenerator.generatePlayer();
    final bulletImg = await GameAssetGenerator.generateBullet();

    final zombieImg = await GameAssetGenerator.generateEnemy(EnemyType.zombie);
    final soldierImg = await GameAssetGenerator.generateEnemy(EnemyType.soldier);
    final alienSmallImg = await GameAssetGenerator.generateEnemy(EnemyType.alienSmall);
    final alienBossImg = await GameAssetGenerator.generateEnemy(EnemyType.alienBoss);
    final maskedEliteImg = await GameAssetGenerator.generateEnemy(EnemyType.maskedElite);

    Flame.images.add('tileset.png', tilesetImg);
    Flame.images.add('player.png', playerImg);
    Flame.images.add('bullet.png', bulletImg);
    Flame.images.add('enemy_zombie.png', zombieImg);
    Flame.images.add('enemy_soldier.png', soldierImg);
    Flame.images.add('enemy_alien_small.png', alienSmallImg);
    Flame.images.add('enemy_alien_boss.png', alienBossImg);
    Flame.images.add('enemy_masked_elite.png', maskedEliteImg);

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
    setState(() {
      _currentWave = current;
      _totalWaves = total;
      _activeEnemies = active;
    });
  }

  void _winLevel() {
    if (_levelWon) return;
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _levelWon = true);

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

  void _onPlayerHealthChanged(double current, double max) {
    setState(() {
      _playerHp = current;
      _playerMaxHp = max;
    });
  }

  void _onPlayerDeath() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _gameOver = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07090F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    final joystick = Joystick(
      directional: JoystickDirectional(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
        size: 80,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: Stack(
        children: [
          BonfireWidget(
            map: _roomDef.map,
            player: AgentQComponent(
              position: _roomDef.playerSpawn,
              idleAnimation: SpriteAnimation.fromFrameData(
                Flame.images.fromCache('player.png'),
                SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
              ),
              runAnimation: SpriteAnimation.fromFrameData(
                Flame.images.fromCache('player.png'),
                SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 32)),
              ),
              onHealthChanged: _onPlayerHealthChanged,
              onDeath: _onPlayerDeath,
            ),
            playerControllers: [joystick, Keyboard()],
            components: [
              WaveManagerComponent(
                room: _roomDef,
                onAllWavesCleared: _winLevel,
                onWaveStatusChanged: _onWaveStatusChanged,
              ),
            ],
            cameraConfig: CameraConfig(
              moveOnlyMapArea: true,
              zoom: 1.5,
            ),
            overlayBuilderMap: {
              'hud': (context, game) => HudOverlay(
                    levelName: 'STAGE ${widget.levelId}',
                    hp: _playerHp,
                    maxHp: _playerMaxHp,
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
            },
            initialActiveOverlays: const ['hud'],
          ),
          if (_levelWon) ...[
            IgnorePointer(child: FireworksDisplay(controller: _fireworksController)),
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
      title: const Text('PAUSED', style: TextStyle(color: Colors.white, letterSpacing: 2)),
      content: const Text('Resume combat or return to Sector map?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () {
            game.resume();
            Navigator.pop(context);
          },
          child: const Text('RESUME', style: TextStyle(color: Color(0xFF00E5FF))),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('RETREAT', style: TextStyle(color: Colors.redAccent)),
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
            boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 15)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 48),
              const SizedBox(height: 16),
              const Text('SECTOR SECURED', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Clear Time: $_timeString', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('PROCEED TO HUB', style: TextStyle(fontWeight: FontWeight.bold)),
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
            boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 15)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('AGENT DOWN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('Mission failed. Target eliminated player.', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ABANDON', style: TextStyle(color: Colors.white70)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AgentQGameWidget(levelId: widget.levelId)),
                      );
                    },
                    child: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
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
