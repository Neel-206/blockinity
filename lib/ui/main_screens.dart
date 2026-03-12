import 'package:blockinity/theme/app_colors.dart';
import 'package:blockinity/ui/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget currentView;
    switch (_selectedIndex) {
      case 0:
        currentView = _buildHomeView();
        break;
      case 1:
        currentView = _buildStoreView();
        break;
      case 2:
        currentView = _buildSocialView();
        break;
      case 3:
        currentView = _buildProfileView();
        break;
      default:
        currentView = _buildHomeView();
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffF7E6DF), Color(0xffF6F2F1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Background decorative cubes
              Positioned(
                top: 50,
                left: -20,
                child: FloatingCube(
                  color: const Color(0xffD8D9E5),
                  size: 100,
                  rotation: 0.2,
                ),
              ),
              Positioned(
                top: 150,
                right: -30,
                child: FloatingCube(
                  color: const Color(0xffE6D8E5),
                  size: 100,
                  rotation: -0.1,
                ),
              ),
              Positioned(
                bottom: 200,
                left: 40,
                child: FloatingCube(
                  color: Colors.greenAccent,
                  size: 60,
                  rotation: 0.1,
                ),
              ),
              Positioned(
                bottom: 300,
                right: 20,
                child: FloatingCube(
                  color: const Color(0xFFFFD700),
                  size: 80,
                  rotation: -0.2,
                ),
              ),

              currentView,

              // Bottom Navigation Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return HomeView();
  }

  Widget _buildStoreView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_rounded, size: 80, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'STORE',
            style: GoogleFonts.sourGummy(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Exciting items coming soon!',
            style: GoogleFonts.poppins(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_rounded, size: 80, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'SOCIAL',
            style: GoogleFonts.sourGummy(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect with your friends!',
            style: GoogleFonts.poppins(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded, size: 80, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'PROFILE',
            style: GoogleFonts.sourGummy(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'View your achievements here.',
            style: GoogleFonts.poppins(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'HOME',
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _buildNavItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'STORE',
                  isActive: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 60), // Space for FAB
                _buildNavItem(
                  icon: Icons.group_rounded,
                  label: 'SOCIAL',
                  isActive: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'PROFILE',
                  isActive: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    showDragHandle: true,
                    context: context,
                    builder: (context) {
                      return const ShowBottomSheet();
                    },
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
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
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors.primary
                : AppColors.subtitle.withOpacity(0.6),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? AppColors.primary
                  : AppColors.subtitle.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingCube extends StatelessWidget {
  final Color color;
  final double size;
  final double rotation;

  const FloatingCube({
    super.key,
    required this.color,
    required this.size,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.4),
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
      ),
    );
  }
}

class ShowBottomSheet extends StatelessWidget {
  const ShowBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Quick Play', style: GoogleFonts.sourGummy()),
                  ],
                ),
              ),
              GestureDetector(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt_rounded,
                        size: 40,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Invite Friends', style: GoogleFonts.sourGummy()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amberAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard_outlined,
                        size: 40,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Daily Gift', style: GoogleFonts.sourGummy()),
                  ],
                ),
              ),
              GestureDetector(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 40,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('New Challanges', style: GoogleFonts.sourGummy()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
