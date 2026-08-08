import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/base/layer.dart';
import '../../core/constants/world_config.dart';

class EnemySpawnData {
  final EnemyType type;
  final Vector2 position;
  final double delay;

  EnemySpawnData({
    required this.type,
    required this.position,
    this.delay = 0.0,
  });
}

class WaveDefinition {
  final int waveNumber;
  final List<EnemySpawnData> spawns;

  WaveDefinition({
    required this.waveNumber,
    required this.spawns,
  });
}

class RoomDefinition {
  final int level;
  final WorldDefinition world;
  final int gridWidth;
  final int gridHeight;
  final double tileSize;
  final Vector2 playerSpawn;
  final WorldMap map;
  final List<WaveDefinition> waves;

  RoomDefinition({
    required this.level,
    required this.world,
    required this.gridWidth,
    required this.gridHeight,
    required this.tileSize,
    required this.playerSpawn,
    required this.map,
    required this.waves,
  });

  /// Programmatically generates a level definition.
  static RoomDefinition generate(int level) {
    final world = WorldConfig.getWorldForLevel(level);
    final isBoss = WorldConfig.isBossLevel(level);
    final isZombieWorld = world.id == 1;

    // Grid sizes: set larger grids to fully occupy modern landscape displays
    final int width = isZombieWorld ? 269 : (isBoss ? 36 : 30);
    final int height = isZombieWorld ? 24 : (isBoss ? 22 : 18);
    const double tileSize = 32.0;

    final List<Tile> tiles = [];
    final List<Vector2> corners = [];

    // Player spawn: Left side for zombie world, center for others
    final playerSpawn = isZombieWorld
        ? Vector2(100.0, WorldConfig.floorY - 105.0)
        : Vector2((width / 2) * tileSize, (height / 2) * tileSize);

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final double screenX = col * tileSize;
        final double screenY = row * tileSize;

        final isWall = (row == 0 || row == height - 1 || col == 0 || col == width - 1);

        if (isWall) {
          tiles.add(
            Tile(
              x: screenX,
              y: screenY,
              width: tileSize,
              height: tileSize,
              sprite: TileSprite(
                path: 'tileset.png',
                position: Vector2(32, 0),
                size: Vector2(32, 32),
              ),
              collisions: [
                RectangleHitbox(
                  size: Vector2(tileSize, tileSize),
                  position: Vector2(0, 0),
                ),
              ],
            ),
          );
        } else {
          // Floor
          tiles.add(
            Tile(
              x: screenX,
              y: screenY,
              width: tileSize,
              height: tileSize,
              sprite: TileSprite(
                path: 'tileset.png',
                position: Vector2(0, 0),
                size: Vector2(32, 32),
              ),
            ),
          );

          // Save valid spawn points
          if (isZombieWorld) {
            if (row == 20 && col >= 10 && col <= width - 6 && col % 5 == 0) {
              corners.add(Vector2(screenX, WorldConfig.floorY - 105.0));
            }
          } else {
            final isEdgeInterior = (row == 2 || row == height - 3 || col == 2 || col == width - 3);
            if (isEdgeInterior) {
              corners.add(Vector2(screenX, screenY));
            }
          }
        }
      }
    }

    final rand = Random(level * 42); // Seeded random for consistent level layouts
    final List<WaveDefinition> wavesList = [];

    if (isBoss) {
      // Boss battle: 1 Wave containing the Boss + periodic adds
      final List<EnemySpawnData> bossSpawns = [];
      // Boss spawns opposite to player (top centerish)
      bossSpawns.add(
        EnemySpawnData(
          type: EnemyType.alienBoss,
          position: Vector2((width / 2) * tileSize, 3 * tileSize),
          delay: 1.0,
        ),
      );

      // Support ads
      final numAds = 3 + (level ~/ 10);
      for (int i = 0; i < numAds; i++) {
        final spawnPos = corners[rand.nextInt(corners.length)];
        final type = world.allowedEnemies[rand.nextInt(world.allowedEnemies.length)];
        bossSpawns.add(
          EnemySpawnData(
            type: type,
            position: spawnPos,
            delay: 3.0 + i * 2.0,
          ),
        );
      }
      wavesList.add(WaveDefinition(waveNumber: 1, spawns: bossSpawns));
    } else {
      // Normal level: multiple waves
      final totalWaves = 2 + (level % 3); // 2 to 4 waves
      final enemiesPerWave = 3 + (level ~/ 4) + (level % 2); // Scales up with level

      for (int wave = 1; wave <= totalWaves; wave++) {
        final List<EnemySpawnData> waveSpawns = [];
        final waveEnemyCount = enemiesPerWave + wave;

        for (int e = 0; e < waveEnemyCount; e++) {
          final spawnPos = corners[rand.nextInt(corners.length)];
          // Select enemy from allowed list, later levels introduce harder archetype (maskedElite)
          EnemyType selectedType = world.allowedEnemies[rand.nextInt(world.allowedEnemies.length)];

          // 20% chance of maskedElite in World 4/5 if unlocked
          if (world.allowedEnemies.contains(EnemyType.maskedElite) && rand.nextDouble() < 0.2) {
            selectedType = EnemyType.maskedElite;
          }

          waveSpawns.add(
            EnemySpawnData(
              type: selectedType,
              position: spawnPos,
              delay: e * 0.8, // Spaced out slightly
            ),
          );
        }
        wavesList.add(WaveDefinition(waveNumber: wave, spawns: waveSpawns));
      }
    }

    return RoomDefinition(
      level: level,
      world: world,
      gridWidth: width,
      gridHeight: height,
      tileSize: tileSize,
      playerSpawn: playerSpawn,
      map: WorldMap([
        Layer(id: 1, tiles: tiles),
      ]),
      waves: wavesList,
    );
  }
}
