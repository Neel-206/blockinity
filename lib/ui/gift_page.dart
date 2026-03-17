import 'dart:async';
import 'dart:math';
import 'package:blockinity/Controller/player_controller.dart';
import 'package:blockinity/Services/daily_reward_service.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Wheel segment data ───────────────────────────────────────────────────────
class _Segment {
  final Color color;
  final String label;
  const _Segment(this.color, this.label);
}

const _segments = [
  _Segment(Color(0xFFF45B1A), '2 Gems'),
  _Segment(Color(0xFF7C4DFF), '50 XP'),
  _Segment(Color(0xFF2196F3), 'Boost'),
  _Segment(Color(0xFFF45B1A), '100 Coins'),
  _Segment(Color(0xFF7C4DFF), '5 Gems'),
  _Segment(Color(0xFF2196F3), '200 Coins'),
  _Segment(Color(0xFFF45B1A), 'Mega'),
  _Segment(Color(0xFF7C4DFF), '500 Coins'),
];

// ─── Streak reward labels per day (day index 0-6) ────────────────────────────
const _streakLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'MEGA'];
const _streakRewards = ['🪙', '🪙', '🪙', '💎', '💎', '🪙', '🎁'];

// ─── Custom wheel painter ─────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final double rotationAngle;
  _WheelPainter(this.rotationAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / _segments.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < _segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      final seg = _segments[i];

      // Fill segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        Paint()..color = seg.color,
      );

      // Divider line
      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        linePaint,
      );

      // Draw rotated reward text in the segment
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.60;
      final textCenter = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      // Split "100 Coins" → line1="100", line2="Coins"
      final parts = seg.label.split(' ');
      final line1 = parts[0];
      final line2 = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      canvas.rotate(textAngle + pi / 2); // rotate text to read outward

      void _drawText(String text, double dy, double fontSize) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, dy));
      }

      _drawText(line1, -18, 13);
      if (line2.isNotEmpty) _drawText(line2, -3, 10);

      canvas.restore();
    }

    canvas.restore();

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    // Hub
    canvas.drawCircle(center, 22, Paint()..color = Colors.white);
    canvas.drawCircle(center, 16, Paint()..color = AppColors.primary);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
    // Pointer
    final ptr = Path()
      ..moveTo(center.dx - 10, 8)
      ..lineTo(center.dx + 10, 8)
      ..lineTo(center.dx, 30)
      ..close();
    canvas.drawPath(ptr, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.rotationAngle != rotationAngle;
}

// ─── Main page ────────────────────────────────────────────────────────────────
class Dailygiftpage extends StatefulWidget {
  const Dailygiftpage({super.key});

  @override
  State<Dailygiftpage> createState() => _DailygiftpageState();
}

class _DailygiftpageState extends State<Dailygiftpage>
    with TickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  double _currentAngle = 0.0; // tracks actual wheel angle across spins
  bool _isSpinning = false;
  String? _wonWheel;  // wheel prize label
  String? _wonStreak; // streak prize label

  /// Live countdown driven by PlayerController.secondsUntilNext
  late Timer _countdownTimer;

  PlayerController get _pc => Get.find<PlayerController>();

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // _spinAnim will be set fresh each spin; initialise to a no-op value
    _spinAnim = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.decelerate));

    // Tick every second to keep the countdown display fresh
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_pc.secondsUntilNext.value > 0) {
        _pc.secondsUntilNext.value--;
        if (_pc.secondsUntilNext.value == 0) {
          _pc.canSpin.value = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  // ── Countdown display ─────────────────────────────────────────────────────
  String _formatCountdown(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  void _handleSpinTap() {
    if (_isSpinning) return;

    if (!_pc.canSpin.value) {
      Get.snackbar(
        '⏳ Not yet!',
        'Next spin in ${_formatCountdown(_pc.secondsUntilNext.value)}',
        backgroundColor: Colors.white,
        colorText: AppColors.navyTitle,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _wonWheel = null;
      _wonStreak = null;
    });

    // Pick a winner and compute target angle
    final rng      = Random();
    final segAngle = 2 * pi / _segments.length;
    final winIndex = rng.nextInt(_segments.length);

    // Spin 5-9 full extra turns, then land precisely on the winning segment
    final extraTurns = (rng.nextInt(5) + 5) * 2 * pi;
    final landAngle  = 2 * pi - (winIndex * segAngle + segAngle / 2);
    final targetAngle = _currentAngle + extraTurns + landAngle;

    // Build the tween from current wheel angle to target each time
    _spinAnim = Tween<double>(begin: _currentAngle, end: targetAngle)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.decelerate));

    _spinCtrl.reset();
    _spinCtrl.forward().then((_) async {
      if (!mounted) return;

      _currentAngle = targetAngle % (2 * pi);

      final reward = _segments[winIndex];

      final result = await _pc.performSpin(reward.label);

      if (!result.allowed) {
        // Edge case: another device already spun
        setState(() => _isSpinning = false);
        Get.snackbar(
          'Already spun!',
          'Next spin in ${_formatCountdown(result.secondsUntilNext)}',
          backgroundColor: Colors.white,
          colorText: AppColors.navyTitle,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final streakLabel = StreakRewardConfig.labels[result.streakDayIndex];

      setState(() {
        _isSpinning = false;
        _wonWheel = reward.label;
        _wonStreak = streakLabel;
      });

      _showWinDialog(reward, streakLabel, result.streakDayIndex + 1);
    });
  }

  void _showWinDialog(_Segment seg, String streakLabel, int streakDay) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            '🎉 You Won!',
            style: GoogleFonts.sourGummy(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wheel prize
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: seg.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: seg.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        seg.label.split(' ')[0],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    seg.label,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyTitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '+ Streak Bonus',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 10),
            // Streak prize
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF45B1A), Color(0xFFD34912)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Day $streakDay: $streakLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: Text(
                'AWESOME!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStreakCard(),
                    const SizedBox(height: 28),
                    _buildWheel(),
                    const SizedBox(height: 22),
                    _buildSpinLabel(),
                    const SizedBox(height: 20),
                    _buildSpinButton(),
                    const SizedBox(height: 14),
                    _buildAdButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'BLOCKINITY',
                style: GoogleFonts.sourGummy(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navyTitle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Obx(() => _currencyPill('${_pc.coins.value}', '🪙')),
          const SizedBox(width: 10),
          Obx(() => _currencyPill('${_pc.gems.value}', '💎')),
        ],
      ),
    );
  }

  Widget _currencyPill(String value, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyTitle,
            ),
          ),
        ],
      ),
    );
  }

  // ── 7-Day streak card ─────────────────────────────────────────────────────
  Widget _buildStreakCard() {
    return Obx(() {
      final activeDay = _pc.streakDayIndex.value; // 0-6

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7-DAY STREAK',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyTitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Day ${activeDay + 1} Active',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Day tiles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final isCurrent = i == activeDay;
                final isDone = i < activeDay;
                final isMega = i == 6;

                final Color bg;
                Color tColor = Colors.white;
                if (isDone) {
                  bg = const Color(0xFF4CAF50);
                } else if (isCurrent) {
                  bg = AppColors.primary;
                } else if (isMega) {
                  bg = const Color(0xFF7C4DFF);
                } else {
                  bg = const Color(0xFFEEF2F8);
                  tColor = AppColors.subtitle;
                }

                return Column(
                  children: [
                    // Glow ring on current day
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isDone ? '✓' : _streakRewards[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: tColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isCurrent ? 'TODAY' : _streakLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: isCurrent || isMega
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrent
                            ? AppColors.primary
                            : isMega
                            ? const Color(0xFF7C4DFF)
                            : AppColors.subtitle,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
            // Hint below tiles
            Center(
              child: Text(
                'SPIN daily to advance your streak! 🔥',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Wheel ─────────────────────────────────────────────────────────────────
  Widget _buildWheel() {
    return AnimatedBuilder(
      animation: _spinCtrl,
      builder: (_, __) {
        final angle = _spinCtrl.isAnimating ? _spinAnim.value : _currentAngle;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 270,
              height: 270,
              child: CustomPaint(painter: _WheelPainter(angle)),
            ),
          ],
        );
      },
    );
  }

  // ── Spin label ────────────────────────────────────────────────────────────
  Widget _buildSpinLabel() {
    return Obx(() {
      final canSpin = _pc.canSpin.value;
      final secs = _pc.secondsUntilNext.value;

      return Column(
        children: [
          Text(
            canSpin
                ? 'FREE SPIN AVAILABLE!'
                : _wonWheel != null
                ? 'WHEEL: $_wonWheel  •  STREAK: $_wonStreak'
                : 'NEXT SPIN AVAILABLE IN',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: canSpin ? const Color(0xFF4CAF50) : AppColors.navyTitle,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (!canSpin) ...[
            const SizedBox(height: 4),
            Text(
              _formatCountdown(secs),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      );
    });
  }

  // ── Spin button ───────────────────────────────────────────────────────────
  Widget _buildSpinButton() {
    return Obx(() {
      final enabled = _pc.canSpin.value && !_isSpinning;
      return GestureDetector(
        onTap: _handleSpinTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? [const Color(0xFFF45B1A), const Color(0xFFD34912)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: _isSpinning ? 1 : 0,
                duration: const Duration(seconds: 4),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SPIN!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Watch ad button ───────────────────────────────────────────────────────
  Widget _buildAdButton() {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Ad',
          'Watch an ad for +1 spin — coming soon!',
          backgroundColor: Colors.white,
          colorText: AppColors.navyTitle,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDF6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'WATCH AD FOR +1 SPIN',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2196F3),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
