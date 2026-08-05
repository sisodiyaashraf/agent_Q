import 'package:flutter/material.dart';
import '../core/constants/world_config.dart';
import '../game/agent_q_game.dart';
import '../services/save_service.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _unlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: WorldConfig.worlds.length, vsync: this);
    _loadProgress();
  }

  void _loadProgress() {
    setState(() {
      _unlockedLevel = SaveService.getUnlockedLevel();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0F24),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Color(0xFF00E5FF), size: 24),
            SizedBox(width: 8),
            Text(
              'AGENT Q // MISSION SELECT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white60, size: 20),
            onPressed: () async {
              await SaveService.resetProgress();
              _loadProgress();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.white54,
          tabs: WorldConfig.worlds.map((world) {
            return Tab(
              child: Text(
                'SECTOR 0${world.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: WorldConfig.worlds.map((world) => _buildWorldGrid(world)).toList(),
      ),
    );
  }

  Widget _buildWorldGrid(WorldDefinition world) {
    final startLevel = (world.id - 1) * WorldConfig.levelsPerWorld + 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            world.primaryColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: WorldConfig.levelsPerWorld,
        itemBuilder: (context, index) {
          final level = startLevel + index;
          final isUnlocked = level <= _unlockedLevel;
          final isBoss = WorldConfig.isBossLevel(level);

          return _buildLevelCard(level, isUnlocked, isBoss, world);
        },
      ),
    );
  }

  Widget _buildLevelCard(int level, bool isUnlocked, bool isBoss, WorldDefinition world) {
    final bestTime = SaveService.getBestTime(level);

    return Card(
      color: isUnlocked ? const Color(0xFF0F1227) : const Color(0xFF070914),
      elevation: isUnlocked ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnlocked
              ? (isBoss ? Colors.redAccent : world.primaryColor.withValues(alpha: 0.4))
              : Colors.white10,
          width: isBoss ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: isUnlocked ? () => _startMission(level) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROOM $level',
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (isBoss)
                    const Icon(Icons.warning, color: Colors.redAccent, size: 16)
                  else if (!isUnlocked)
                    const Icon(Icons.lock, color: Colors.white24, size: 14),
                ],
              ),
              const Spacer(),
              if (isUnlocked) ...[
                if (bestTime > 0)
                  Text(
                    'RECORD: ${bestTime}s',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontFamily: 'Courier'),
                  )
                else
                  Text(
                    isBoss ? 'BOSS INCOMING' : 'UNSECURED',
                    style: TextStyle(
                      color: isBoss ? Colors.redAccent : Colors.amberAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'LAUNCH',
                      style: TextStyle(
                        color: isBoss ? Colors.redAccent : world.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isBoss ? Colors.redAccent : world.primaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('LOCKED', style: TextStyle(color: Colors.white12, fontSize: 10, letterSpacing: 1.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startMission(int levelId) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => AgentQGameWidget(levelId: levelId),
      ),
    )
        .then((_) => _loadProgress());
  }
}
