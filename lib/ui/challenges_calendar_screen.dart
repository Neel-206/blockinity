import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../Services/daily_challenge_service.dart';
import '../theme/app_colors.dart';

class ChallengesCalendarScreen extends StatefulWidget {
  const ChallengesCalendarScreen({super.key});

  @override
  State<ChallengesCalendarScreen> createState() => _ChallengesCalendarScreenState();
}

class _ChallengesCalendarScreenState extends State<ChallengesCalendarScreen> {
  late DateTime _selectedMonth;
  final DailyChallengeService _service = DailyChallengeService();
  final Map<String, bool> _completionStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadCompletionStatus();
  }

  Future<void> _loadCompletionStatus() async {
    setState(() => _isLoading = true);
    try {
      final results = await _service.getCompletionStatusForMonth(_selectedMonth);
      _completionStatus.clear();
      _completionStatus.addAll(results);
    } catch (e) {
      debugPrint('Error loading completion status: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _completionStatus.clear();
    });
    _loadCompletionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMonthSelector(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildCalendarGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            'Daily Challenges',
            style: GoogleFonts.sourGummy(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, size: 32),
            color: AppColors.primary,
          ),
          Text(
            monthName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, size: 32),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    
    // Adjust for Monday start (weekday is 1-7, where 1 is Mon)
    final emptyBefore = firstDayWeekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWeekDaysHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: daysInMonth + emptyBefore,
              itemBuilder: (context, index) {
                if (index < emptyBefore) return const SizedBox.shrink();
                
                final day = index - emptyBefore + 1;
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                return _buildDayCell(date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.isAtSameMomentAs(today);
    final isFuture = date.isAfter(today);
    final isCompleted = _completionStatus[DailyChallengeService.dateToKey(date)] ?? false;

    Color bgColor;
    Color textColor;
    IconData? icon;

    if (isFuture) {
      bgColor = Colors.grey.withOpacity(0.1);
      textColor = AppColors.textSecondary.withOpacity(0.3);
      icon = Icons.lock_outline_rounded;
    } else if (isCompleted) {
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (isToday) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else {
      // Past but not completed
      bgColor = Colors.white;
      textColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: isFuture ? null : () => _startChallenge(date, isCompleted),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFuture ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isToday ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(height: 4),
              Icon(icon, size: 16, color: textColor),
            ],
            if (!isFuture && !isCompleted && !isToday) ...[
               const SizedBox(height: 4),
               Icon(Icons.play_circle_outline_rounded, size: 16, color: AppColors.primary),
            ]
          ],
        ),
      ),
    );
  }

  void _startChallenge(DateTime date, bool isCompleted) async {
    if (isCompleted) {
      Get.snackbar(
        '✅ Challenge Clear!',
        'You already earned rewards for this day.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      // Optional: still allow play but no rewards? 
      // User said "user play any time that challange", so maybe let them play.
    }

    final config = DailyChallengeService.generateChallengeForDate(date);
    
    Get.toNamed('/game', arguments: {
      'isChallenge': true,
      'challengeSeed': config.seed,
      'targetScore': config.targetScore,
      'targetCartoons': config.targetCartoons,
      'targetLines': config.targetLines,
      'targetCombos': config.targetCombos,
      'targetPerfectFits': config.targetPerfectFits,
      'obstacles': config.obstacles,
      'coinReward': config.coinReward,
      'gemReward': config.gemReward,
      'challengeDate': date, // Pass the date to mark completion later
    })?.then((_) => _loadCompletionStatus()); // Refresh on return
  }
}
