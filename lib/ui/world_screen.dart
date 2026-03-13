import 'package:blockinity/Controller/level_controller.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

enum WorldStatus { unlocked, active, locked, comingSoon }

class WorldModel {
  final String title;
  final String subtitle;
  final int currentLevel;
  final int totalLevels;
  final WorldStatus status;
  final Color themeColor;
  final int? unlockLevel;

  WorldModel({
    required this.title,
    required this.subtitle,
    required this.currentLevel,
    required this.totalLevels,
    required this.status,
    required this.themeColor,
    this.unlockLevel,
  });
}

class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  final List<WorldModel> _rawWorldsData = [
    WorldModel(
      title: 'World 1',
      subtitle: 'Neon Forest',
      currentLevel: 0,
      totalLevels: 20,
      status: WorldStatus.active,
      themeColor: const Color(0xff27AE60),
    ),
    WorldModel(
      title: 'World 2',
      subtitle: 'Crystal Peaks',
      currentLevel: 0,
      totalLevels: 20,
      status: WorldStatus.locked,
      themeColor: const Color(0xff4A5AE0),
      unlockLevel: 20,
    ),
    WorldModel(
      title: 'World 3',
      subtitle: 'Lava Lake',
      currentLevel: 0,
      totalLevels: 20,
      status: WorldStatus.locked,
      themeColor: const Color(0xff7D5A50),
      unlockLevel: 40,
    ),
    WorldModel(
      title: '',
      subtitle: '',
      currentLevel: 0,
      totalLevels: 0,
      status: WorldStatus.comingSoon,
      themeColor: Colors.transparent,
    ),
  ];

  List<WorldModel> get worldsData {
    List<WorldModel> processed = [];
    final LevelController levelController = Get.find<LevelController>();

    for (var i = 0; i < _rawWorldsData.length; i++) {
      var world = _rawWorldsData[i];
      if (world.status == WorldStatus.comingSoon) {
        processed.add(world);
        continue;
      }

      int worldProgress = levelController.getProgressForWorld(i);
      
      WorldStatus dynamicStatus;
      bool previousWorldCleared = i == 0 || 
          (levelController.getProgressForWorld(i - 1) >= _rawWorldsData[i-1].totalLevels);

      if (previousWorldCleared) {
        if (worldProgress >= world.totalLevels && world.totalLevels > 0) {
          dynamicStatus = WorldStatus.unlocked;
        } else {
          dynamicStatus = WorldStatus.active;
        }
      } else {
        dynamicStatus = WorldStatus.locked;
      }

      processed.add(
        WorldModel(
          title: world.title,
          subtitle: world.subtitle,
          currentLevel: worldProgress,
          totalLevels: world.totalLevels,
          status: dynamicStatus,
          themeColor: world.themeColor,
          unlockLevel: world.unlockLevel,
        ),
      );
    }
    return processed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Obx(() {
                  return Column(
                    children: [
                      for (int i = 0; i < worldsData.length; i++)
                        _buildWorldCard(worldsData[i], i),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xff1E293B),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 48),
                child: Text(
                  'EXPLORE WORLDS',
                  style: GoogleFonts.sourGummy(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xff1E293B),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldCard(WorldModel world, int index) {
    if (world.status == WorldStatus.comingSoon) {
      return _buildComingSoonCard();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        world.themeColor,
                        world.themeColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 15,
                        left: 15,
                        child: _buildStatusBadge(world),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${world.title}: ${world.subtitle}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyTitle,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.subtitle.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      '${world.currentLevel} / ${world.totalLevels} Levels',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyTitle.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildProgressBar(world),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildActionButton(world, index),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (world.status == WorldStatus.locked)
              _buildLockedOverlay(world, index),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(WorldModel world) {
    String text = 'UNLOCKED';
    Color textColor = world.themeColor;

    if (world.status == WorldStatus.active) {
      text = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProgressBar(WorldModel world) {
    double progress =
        world.currentLevel / (world.totalLevels > 0 ? world.totalLevels : 1);
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffF0F1F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: world.status == WorldStatus.locked
                ? Colors.grey.shade300
                : world.themeColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(WorldModel world, int index) {
    String text = 'PLAY';
    Color color = const Color(0xffF15A24);

    if (world.status == WorldStatus.active) {
      text = 'PLAY';
    } else if (world.status == WorldStatus.locked) {
      text = 'LOCKED';
      color = const Color(0xff9EAFC3);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: world.status != WorldStatus.locked
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: world.status == WorldStatus.locked
            ? null
            : () {
                Get.toNamed('/levels', arguments: {'world': world, 'index': index});
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          disabledForegroundColor: Colors.white.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(100, 45),
          maximumSize: const Size(140, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: FittedBox(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay(WorldModel world, int index) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                'Complete World $index to Unlock',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(35),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffE9EFF5).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xffCAD6E2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.rocket_launch_rounded,
            color: Color(0xff9EAFC3),
            size: 45,
          ),
          const SizedBox(height: 15),
          Text(
            'Coming Soon!',
            style: GoogleFonts.sourGummy(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xff7D8FA4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New dimensions are being discovered\nby the Cuboria scientists.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xff7D8FA4),
            ),
          ),
        ],
      ),
    );
  }
}
