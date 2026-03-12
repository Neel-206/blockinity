import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 10),
        // Title Section
        _buildTitleSection(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Main Play Button Area
                _buildCenterPlayButton(),
                const SizedBox(height: 40),
                // Menu Buttons
                _buildMenuButtons(),
                const SizedBox(height: 120), // Space for bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }

   Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'BLOCKINITY',
          style: GoogleFonts.sourGummy(
            fontSize: 50,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        Text(
          'BLOCK PUZZLE ADVENTURE',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle.withOpacity(0.8),
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

   Widget _buildCenterPlayButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft rounded background container
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xffF8E7E0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffF5DACD),
                blurRadius: 40,
                spreadRadius: 20,
              ),
            ],
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        // Pulsing Play Button
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.orangeGradientStart,
                  AppColors.orangeGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Handle play button tap
                  Get.toNamed('/game');
                },
                customBorder: const CircleBorder(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                    Text(
                      'PLAY',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildActionButton(
            label: 'Worlds',
            icon: Icons.grid_view_rounded,
            fullWidth: true,
            onTap: () {
              Get.toNamed('/world');
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: '',
                  icon: Icons.settings_rounded,
                  onTap: () {
                    
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildActionButton(
                  label: '',
                  icon: Icons.emoji_events_rounded,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildActionButton({
    required String label,
    required IconData icon,
    bool fullWidth = false,
    VoidCallback? onTap,  
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap?.call(),
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 15),
                  Text(
                    label,
                    style: GoogleFonts.sourGummy(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyTitle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Currency/Points Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '0',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyTitle,
                  ),
                ),
              ],
            ),
          ),

          // Notification Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppColors.navyTitle,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}