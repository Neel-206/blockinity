import 'package:blockinity/Controller/level_controller.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:blockinity/ui/world_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  late WorldModel world;
  late int worldIndex;
  late LevelController levelController;

  @override
  void initState() {
    super.initState();
    levelController = Get.find<LevelController>();
    
    if (Get.arguments is Map) {
      world = Get.arguments['world'];
      worldIndex = Get.arguments['index'];
    } else {
      // Fallback
      world = Get.arguments ??
          WorldModel(
            title: 'WORLD 1',
            subtitle: 'NEON CUBES',
            currentLevel: 0,
            totalLevels: 20,
            status: WorldStatus.active,
            themeColor: AppColors.primary,
          );
      worldIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFDFBFA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(child: _buildLevelGrid()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Get.back(),
            color: const Color(0xffFFF1EC),
            iconColor: AppColors.primary,
          ),
          Column(
            children: [
              Text(
                'Select Level',
                style: GoogleFonts.sourGummy(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff1E293B),
                ),
              ),
              Text(
                '${world.title}: ${world.subtitle}'.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          _buildCircleButton(
            icon: Icons.settings_rounded,
            onPressed: () {},
            color: const Color(0xffFFF1EC),
            iconColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildLevelGrid() {
    return Obx(() {
      // Accessing value here ensures Obx registers the observable
      final currentUnlocked = levelController.unlockedLevel.value;

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
          childAspectRatio: 0.8,
        ),
        itemCount: world.totalLevels,
        itemBuilder: (context, index) {
          int levelNumInWorld = index + 1;
          int absoluteLevel = (worldIndex * 20) + levelNumInWorld;

          bool isLocked = absoluteLevel > currentUnlocked + 1;
          bool isCurrent = absoluteLevel == currentUnlocked + 1;
          bool isCompleted = absoluteLevel <= currentUnlocked;

          return _buildLevelCard(
            absoluteLevel,
            isLocked,
            isCurrent,
            isCompleted,
          );
        },
      );
    });
  }

  Widget _buildLevelCard(
      int level, bool isLocked, bool isCurrent, bool isCompleted) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!isLocked) {
                Get.toNamed('/game', arguments: level);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xffEDF2F7)
                    : isCurrent
                        ? const Color(0xffFCEEE8)
                        : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                border: isCurrent
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2,
                        style: BorderStyle.solid,
                      )
                    : null,
                boxShadow: !isLocked && !isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_rounded, color: Color(0xff94A3B8), size: 28)
                    : Text(
                        '$level',
                        style: GoogleFonts.sourGummy(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isCurrent ? AppColors.primary : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildStars(isCompleted, level == world.currentLevel && world.currentLevel > 0),
      ],
    );
  }

  Widget _buildStars(bool isCompleted, bool isAlmostDone) {
    // In a real app, stars would come from level data
    // Here we simulate for design purposes
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool starFilled = isCompleted && (index < 3); // All 3 for completed levels
        if (isAlmostDone && index == 2) starFilled = false; // Example 2 stars
        
        return Icon(
          Icons.star_rounded,
          size: 16,
          color: starFilled ? const Color(0xffFFB800) : const Color(0xffCBD5E1),
        );
      }),
    );
  }

  // Widget _buildBottomNav() {
  //   return Container(
  //     height: 100,
  //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(40),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 20,
  //           offset: const Offset(0, -5),
  //         ),
  //       ],
  //     ),
  //     child: Stack(
  //       clipBehavior: Clip.none,
  //       alignment: Alignment.center,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 40),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               _buildNavItem(icon: Icons.home_rounded, label: 'HOME'),
  //               _buildNavItem(icon: Icons.shopping_bag_rounded, label: 'SHOP'),
  //             ],
  //           ),
  //         ),
  //         Positioned(
  //           top: -25,
  //           child: Column(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(4),
  //                 decoration: const BoxDecoration(
  //                   color: Colors.white,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Container(
  //                   width: 65,
  //                   height: 65,
  //                   decoration: BoxDecoration(
  //                     gradient: const LinearGradient(
  //                       colors: [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                     ),
  //                     shape: BoxShape.circle,
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: AppColors.primary.withOpacity(0.3),
  //                         blurRadius: 15,
  //                         offset: const Offset(0, 8),
  //                       ),
  //                     ],
  //                   ),
  //                   child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 32),
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 'LEVELS',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w800,
  //                   color: AppColors.primary,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildNavItem({required IconData icon, required String label}) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Icon(icon, color: const Color(0xff94A3B8), size: 28),
  //       const SizedBox(height: 4),
  //       Text(
  //         label,
  //         style: GoogleFonts.poppins(
  //           fontSize: 10,
  //           fontWeight: FontWeight.w700,
  //           color: const Color(0xff94A3B8),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
