import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
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
  final List<WorldModel> worldsData = [
    WorldModel(
      title: 'World 1',
      subtitle: 'Neon Forest',
      currentLevel: 15,
      totalLevels: 20,
      status: WorldStatus.unlocked,
      themeColor: const Color(0xff27AE60),
    ),
    WorldModel(
      title: 'World 2',
      subtitle: 'Crystal Peaks',
      currentLevel: 8,
      totalLevels: 20,
      status: WorldStatus.active,
      themeColor: const Color(0xff4A5AE0),
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
                child: Column(
                  children: [
                    for (var world in worldsData) _buildWorldCard(world),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
     // bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xff1E293B)),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 48), // Precise alignment
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

  Widget _buildWorldCard(WorldModel world) {
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          _buildActionButton(world),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (world.status == WorldStatus.locked) _buildLockedOverlay(world),
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
    double progress = world.currentLevel / (world.totalLevels > 0 ? world.totalLevels : 1);
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
            color: world.status == WorldStatus.locked ? Colors.grey.shade300 : world.themeColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(WorldModel world) {
    String text = 'PLAY';
    Color color = const Color(0xffF15A24);

    if (world.status == WorldStatus.active) {
      text = 'CONTINUE';
    } else if (world.status == WorldStatus.locked) {
      text = 'LOCKED';
      color = const Color(0xff9EAFC3);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 100), // Constraint width here
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
        onPressed: world.status == WorldStatus.locked ? null : () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          disabledForegroundColor: Colors.white.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(100, 45), // Explicit finite size
          maximumSize: const Size(140, 45), // Prevent overflow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: FittedBox( // Ensure text fits
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

  Widget _buildLockedOverlay(WorldModel world) {
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
                'Unlock at Level ${world.unlockLevel}',
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
          const Icon(Icons.rocket_launch_rounded, color: Color(0xff9EAFC3), size: 45),
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

  // Widget _buildBottomNav() {
  //   return Container(
  //     height: 85,
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: const BorderRadius.only(
  //         topLeft: Radius.circular(30),
  //         topRight: Radius.circular(30),
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 20,
  //           offset: const Offset(0, -5),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildNavItem(icon: Icons.home_rounded, label: 'HOME'),
  //         _buildNavItem(icon: Icons.public_rounded, label: 'WORLDS', isActive: true),
  //         _buildNavItem(icon: Icons.shopping_cart_rounded, label: 'SHOP'),
  //         _buildNavItem(icon: Icons.person_rounded, label: 'PROFILE'),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildNavItem({required IconData icon, required String label, bool isActive = false}) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Icon(
  //         icon,
  //         color: isActive ? const Color(0xffF15A24) : const Color(0xff9EAFC3),
  //         size: 26,
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         label,
  //         style: GoogleFonts.poppins(
  //           fontSize: 10,
  //           fontWeight: FontWeight.w800,
  //           color: isActive ? const Color(0xffF15A24) : const Color(0xff9EAFC3),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}