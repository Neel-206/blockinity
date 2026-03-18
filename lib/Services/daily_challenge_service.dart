import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Config generated for today's daily challenge.
class DailyChallengeConfig {
  /// Deterministic "level" seed for today — used to seed board randomness.
  final int seed;

  /// Target score players must reach to complete the challenge.
  final int targetScore;

  /// Number of cartoon targets to collect.
  final int targetCartoons;

  /// Number of pre-filled obstacle cells.
  final int obstacles;

  /// Coin reward on first win.
  final int coinReward;

  /// Gem reward on first win.
  final int gemReward;

  const DailyChallengeConfig({
    required this.seed,
    required this.targetScore,
    required this.targetCartoons,
    required this.obstacles,
    required this.coinReward,
    required this.gemReward,
  });
}

class DailyChallengeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? get _uid => _auth.currentUser?.uid;

  /// Returns "YYYY-MM-DD" key for today.
  static String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Generates today's challenge config deterministically from the date.
  ///
  /// Every player worldwide gets the exact same challenge on the same day.
  static DailyChallengeConfig generateTodayChallenge() {
    final now     = DateTime.now();
    // Integer seed from date: e.g. 20260317
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;

    // Vary difficulty across the week (Mon=1 easy → Sun=7 hard)
    final weekday  = now.weekday; // 1-7
    final baseScore = 250 + weekday * 50;     // 300-600
    final cartoons  = 2 + (weekday ~/ 2);     // 2-5
    final obstacles = 0; // Obstacles removed as per user request

    return DailyChallengeConfig(
      seed:          dateSeed,
      targetScore:   baseScore,
      targetCartoons: cartoons,
      obstacles:     obstacles,
      coinReward:    100,
      gemReward:     3,
    );
  }

  /// Returns true if today's challenge has already been completed.
  Future<bool> isTodayCompleted() async {
    if (_uid == null) return false;
    try {
      final snap = await _db
          .child('Users/${_uid!}/dailyChallenge/$todayKey')
          .get();
      return snap.exists && snap.value == true;
    } catch (e) {
      debugPrint('DailyChallengeService.isTodayCompleted error: $e');
      return false;
    }
  }

  /// Marks today's challenge as completed.
  Future<void> markTodayCompleted() async {
    if (_uid == null) return;
    try {
      await _db
          .child('Users/${_uid!}/dailyChallenge/$todayKey')
          .set(true);
    } catch (e) {
      debugPrint('DailyChallengeService.markTodayCompleted error: $e');
    }
  }
}
