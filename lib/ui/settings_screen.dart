import 'package:blockinity/Controller/auth_controller.dart';
import 'package:blockinity/Controller/player_controller.dart';
import 'package:blockinity/Controller/settings_controller.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final playerController = Get.find<PlayerController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 25),
                    
                    // Audio & Haptics Section
                    _buildSectionHeader('Audio & Haptics', icon: Icons.tune_rounded),
                    _buildSettingsContainer([
                      Obx(() => _buildToggleItem(
                        icon: Icons.volume_up_rounded,
                        color: const Color(0xFFE28B6B),
                        title: 'Sound Effects',
                        value: settingsController.soundEffects.value,
                        onChanged: settingsController.toggleSound,
                      )),
                      Obx(() => _buildToggleItem(
                        icon: Icons.music_note_rounded,
                        color: const Color(0xFF7BAEEB),
                        title: 'Music',
                        value: settingsController.music.value,
                        onChanged: settingsController.toggleMusic,
                      )),
                      Obx(() => _buildToggleItem(
                        icon: Icons.vibration_rounded,
                        color: const Color(0xFFA58BED),
                        title: 'Vibration',
                        value: settingsController.vibration.value,
                        onChanged: settingsController.toggleVibration,
                      )),
                    ]),
                    
                    const SizedBox(height: 30),

                    // Notifications Section
                    _buildSectionHeader('Notifications', icon: Icons.notifications_rounded),
                    _buildSettingsContainer([
                      Obx(() => _buildToggleItem(
                        icon: Icons.card_giftcard_rounded,
                        color: const Color(0xFFE28B6B),
                        title: 'Daily Rewards',
                        value: settingsController.dailyRewardsNotify.value,
                        onChanged: settingsController.toggleDailyRewards,
                      )),
                      Obx(() => _buildToggleItem(
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFF7BAEEB),
                        title: 'Event Updates',
                        value: settingsController.eventUpdatesNotify.value,
                        onChanged: settingsController.toggleEventUpdates,
                      )),
                    ]),

                    const SizedBox(height: 30),

                    // Account Section
                    _buildSectionHeader('Account', icon: Icons.person_pin_rounded, iconColor: const Color(0xFFA58BED)),
                    _buildAccountCard(authController, playerController),
                    const SizedBox(height: 15),
                    _buildCloudSaveItem(),
                    const SizedBox(height: 15),
                    _buildSignOutButton(authController),

                    const SizedBox(height: 30),

                    // Support Section
                    _buildSectionHeader('Support & Info', icon: Icons.info_rounded, iconColor: const Color(0xFF64748B)),
                    _buildSettingsContainer([
                      _buildListItem(
                        icon: Icons.help_outline_rounded,
                        color: const Color(0xFFA58BED),
                        title: 'Help Center',
                        trailing: const Icon(Icons.open_in_new_rounded, size: 20, color: Color(0xFFCBD5E1)),
                      ),
                      _buildListItem(
                        icon: Icons.description_outlined,
                        color: const Color(0xFFA58BED),
                        title: 'Terms of Service',
                        trailing: const Icon(Icons.chevron_right_rounded, size: 24, color: Color(0xFFCBD5E1)),
                      ),
                      _buildListItem(
                        icon: Icons.shield_outlined,
                        color: const Color(0xFFA58BED),
                        title: 'Privacy Policy',
                        trailing: const Icon(Icons.chevron_right_rounded, size: 24, color: Color(0xFFCBD5E1)),
                      ),
                    ]),

                    const SizedBox(height: 40),
                    _buildVersionTag(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          //  _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          ),
          Text(
            'Blockinity',
            style: GoogleFonts.sourGummy(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2EAF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFFA58BED), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GAME HUB',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFA58BED),
            letterSpacing: 2,
          ),
        ),
        Text(
          'Settings',
          style: GoogleFonts.sourGummy(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppColors.navyTitle,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navyTitle,
            ),
          ),
          Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5E1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color color,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildAccountCard(AuthController authController, PlayerController playerController) {
    return Obx(() {
      final user = authController.user.value;
      final name = user?.displayName ?? 'Player 1';
      final level = playerController.unlockedLevel.value;
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE28B6B)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.white,
                  child: user?.photoURL != null 
                    ? Image.network(user!.photoURL!)
                    : const Icon(Icons.person, color: AppColors.primary, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Level $level Architect',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 30),
          ],
        ),
      );
    });
  }

  Widget _buildCloudSaveItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE2EAF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF0066FF), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Cloud Save',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'SYNCED',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(AuthController authController) {
    return GestureDetector(
      onTap: () => authController.logout(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionTag() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          'BLOCKINITY V1.0.0-STABLE',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
