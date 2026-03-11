import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../routes/app_routes.dart';

class SplaseScreen extends StatefulWidget {
  const SplaseScreen({super.key});

  @override
  State<SplaseScreen> createState() => _SplaseScreenState();
}

class _SplaseScreenState extends State<SplaseScreen>
    with TickerProviderStateMixin {
  late AnimationController containerController;
  late AnimationController imageController;
  late AnimationController cubesController;
  late AnimationController loadingController;

  late Animation<double> containerScale;
  late Animation<double> imageBounce;
  late Animation<double> cubesSpread;
  late Animation<double> loadingFade;

  double progress = 0;

  @override
  void initState() {
    super.initState();

    /// Container appear animation
    containerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    containerScale = CurvedAnimation(
      parent: containerController,
      curve: Curves.easeOutBack,
    );

    /// Image bounce animation
    imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    imageBounce = CurvedAnimation(
      parent: imageController,
      curve: Curves.bounceOut,
    );

    /// Cubes spread animation
    cubesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    cubesSpread = CurvedAnimation(
      parent: cubesController,
      curve: Curves.easeOut,
    );

    /// Loading animation
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    loadingFade = CurvedAnimation(
      parent: loadingController,
      curve: Curves.easeIn,
    );

    startAnimationSequence();
  }

  void startAnimationSequence() async {
    await containerController.forward();

    await imageController.forward();

    await cubesController.forward();

    await loadingController.forward();

    startLoading();
  }

  void startLoading() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (progress >= 1) {
        timer.cancel();
        // Navigate to Login after loading
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offNamed(AppRoutes.login);
        });
      } else {
        setState(() {
          progress += 0.02;
        });
      }
    });
  }

  @override
  void dispose() {
    containerController.dispose();
    imageController.dispose();
    cubesController.dispose();
    loadingController.dispose();
    super.dispose();
  }

  Widget animatedCube(
    double top,
    double left,
    Color color,
    double size,
    double rotation,
  ) {
    return AnimatedBuilder(
      animation: cubesSpread,
      builder: (context, child) {
        return Positioned(
          top: top * cubesSpread.value + 350 * (1 - cubesSpread.value),
          left: left * cubesSpread.value + 180 * (1 - cubesSpread.value),
          child: FloatingCube(color: color, size: size, rotation: rotation),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          /// Animated Cubes
          animatedCube(50, 40, const Color(0xFFFFDBCB), 40, 0.2),
          animatedCube(
            60,
            300,
            const Color.fromARGB(255, 208, 208, 208),
            40,
            -0.2,
          ),
          animatedCube(180, 320, const Color(0xFFD6E3FF), 40, -0.1),
          animatedCube(
            150,
            200,
            const Color.fromARGB(255, 249, 162, 191),
            45,
            -0.2,
          ),
          animatedCube(
            200,
            50,
            const Color.fromARGB(255, 193, 246, 94),
            50,
            0.1,
          ),
          animatedCube(500, 30, const Color(0xFF7FB2FF), 50, 0.1),
          animatedCube(420, 20, const Color(0xFFE5D1FF), 30, -0.2),
          animatedCube(650, 80, const Color(0xFFFFF4D1), 55, 0.3),
          animatedCube(720, 260, const Color(0xFFD1F2E1), 80, 0.15),
          
          animatedCube(440, 320, Colors.greenAccent, 60, 0),
          animatedCube(260, 340, const Color(0xFFFFD700), 60, 0.1),
          /// Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 230),

                /// Animated Container
                ScaleTransition(
                  scale: containerScale,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: const BoxDecoration(
                      color: Color(0xffF8E7E0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xffF5DACD),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),

                    /// Bouncing Image
                    child: ScaleTransition(
                      scale: imageBounce,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Image(image: AssetImage('images/splash.png')),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                FadeTransition(
                  opacity: loadingFade,
                  child: Text(
                    'Blockinity',
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontFamily: GoogleFonts.sourGummy().fontFamily,
                      color: const Color(0xFFE95D24),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                /// Loading Fade Animation
                FadeTransition(
                  opacity: loadingFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Loading Assets...',
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFFE95D24),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: AppColors.primaryLight.withOpacity(0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                const Text(
                  'STUDIO CUBO',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    letterSpacing: 4,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videogame_asset, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
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
          color: color.withOpacity(0.6),
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
      ),
    );
  }
}
