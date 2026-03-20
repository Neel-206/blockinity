import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class GameOver extends StatelessWidget {
  const GameOver({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments ?? {};
    final int score = args['score'] ?? 0;
    final int earnedCoins = args['earnedCoins'] ?? 0;
    final int earnedGems = args['earnedGems'] ?? 0;
    final int stars = args['stars'] ?? 0;
    final bool isWin = args['isWin'] ?? false;
    final String title1 = args['title1'] ?? (isWin ? 'LEVEL' : 'TRY');
    final String title2 = args['title2'] ?? (isWin ? 'CLEAR' : 'AGAIN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                _buildHeader(),
                _buildGameOverTitle(title1, title2),
                const SizedBox(height: 5),
                _buildStarCard(stars, score),
                const SizedBox(height: 20),
                _buildScoreRow(earnedCoins, earnedGems),
                const SizedBox(height: 20),
                _buildActionButtons(isWin),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 20, // Specific alignment
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F4F9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF1F2633),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Blockinity',
              style: GoogleFonts.sourGummy(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF46B22),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverTitle(String title1, String title2) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Slanted Background Square
          Transform.rotate(
            angle: -0.1,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE4D4).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform(
                transform: Matrix4.skewX(-0.15),
                child: Text(
                  title1,
                  style: GoogleFonts.poppins(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1F2633),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Transform(
                transform: Matrix4.skewX(-0.15),
                child: Text(
                  title2,
                  style: GoogleFonts.poppins(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF46B22),
                    fontStyle: FontStyle.italic,
                    height: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarCard(int stars, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Icon(
                Icons.star_rounded,
                size: 64, // Slightly larger since there are fewer now
                color: index < stars
                    ? const Color(0xFFF46B22)
                    : const Color(0xFFE9F1F7),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            'Great Effort!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF46B22),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SCORE ACHIEVED',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2633).withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
          Text(
            score.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            ),
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2633),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(int earnedCoins, int earnedGems) {
    return Row(
      children: [
        Expanded(
          child: _buildScoreBox(
            'EARNED COINS',
            earnedCoins.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            ),
            const Color(0xFFFDE4D4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildScoreBox(
            'GEMS ACHIEVED',
            earnedGems.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            ),
            const Color(0xFFE9F1F7),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBox(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2633).withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2633),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isWin) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: isWin
                ? () {
                    Get.back(result: 'next');
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF46B22),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              elevation: isWin ? 4 : 0,
              shadowColor: const Color(0xFFF46B22).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 32),
                const SizedBox(width: 8),
                Text(
                  'NEXT LEVEL',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(Icons.refresh_rounded, 'RETRY', () {
                Get.back(result: 'retry');
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryButton(Icons.home_rounded, 'HOME', () {
                Get.back(result: 'home');
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE9F1F7),
          foregroundColor: const Color(0xFF1F2633),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
