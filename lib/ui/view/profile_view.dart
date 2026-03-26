import 'package:blockinity/Controller/auth_controller.dart';
import 'package:blockinity/Controller/level_controller.dart';
import 'package:blockinity/Controller/player_controller.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final playerController = Get.find<PlayerController>();
    final levelController = Get.find<LevelController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          // Top Bar 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back,
                      color: Color(0xFF64748B), size: 26),
                ),
                Text(
                  'Blockinity Profile',
                  style: GoogleFonts.sourGummy(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyTitle,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed('/setting'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings,
                        color: Color(0xFF64748B), size: 22),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Avatar Section
          Obx(() {
            final user = authController.user.value;
            final name = user?.displayName ?? 'Player';
            final level = levelController.unlockedLevel.value;
            final title = _getTitleForLevel(level);

            return Column(
              children: [
                // Avatar with edit button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFE28B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: user?.photoURL != null
                              ? Image.network(user!.photoURL!,
                                  fit: BoxFit.cover)
                              : const Icon(Icons.person,
                                  color: AppColors.primary, size: 55),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyTitle,
                  ),
                ),

                const SizedBox(height: 8),

                // Level badge + title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF4CAF50), width: 1),
                      ),
                      child: Text(
                        'LEVEL $level',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),

          const SizedBox(height: 28),

          // ── Statistics Section ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATISTICS',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyTitle,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Row of stat cards
                Obx(() {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.primary,
                          label: 'HIGHEST SCORE',
                          labelColor: AppColors.primary,
                          value: _formatNumber(
                              playerController.highestScore.value),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.grid_view_rounded,
                          iconColor: const Color(0xFF1A73E8),
                          label: 'BLOCKS CLEARED',
                          labelColor: const Color(0xFF1A73E8),
                          value: _formatNumber(
                              playerController.blocksCleared.value),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 14),

                // Worlds Unlocked card
                Obx(() {
                  final level = levelController.unlockedLevel.value;
                  final worldsUnlocked = (level / 20).ceil().clamp(0, 20);
                  const totalWorlds = 8;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.public_rounded,
                                      color: const Color(0xFF4CAF50), size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'WORLDS UNLOCKED',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4CAF50),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$worldsUnlocked / $totalWorlds',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyTitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Mini world indicators
                        Row(
                          children: List.generate(5, (index) {
                            final filled = index < worldsUnlocked;
                            return Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: filled
                                    ? AppColors.navyTitle
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helper: Stat Card ──────────────────────────────────────────────────────
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.navyTitle,
            ),
          ),
        ],
      ),
    );
  }

  // ── Data helpers ───────────────────────────────────────────────────────────

  String _getTitleForLevel(int level) {
    if (level >= 80) return 'Grand Master';
    if (level >= 60) return 'Master Builder';
    if (level >= 40) return 'Expert';
    if (level >= 20) return 'Architect';
    if (level >= 10) return 'Builder';
    if (level >= 5) return 'Apprentice';
    return 'Rookie';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}