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

  /// Target total lines cleared.
  final int targetLines;

  /// Target total combos performed.
  final int targetCombos;

  /// Target total "Perfect-Fit" placements (high adjacency).
  final int targetPerfectFits;

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
    required this.targetLines,
    required this.targetCombos,
    required this.targetPerfectFits,
    required this.obstacles,
    required this.coinReward,
    required this.gemReward,
  });
}

class DailyChallengeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? get _uid => _auth.currentUser?.uid;

  /// Returns "YYYY-MM-DD" key for a given date.
  static String dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Returns "YYYY-MM-DD" key for today.
  static String get todayKey => dateToKey(DateTime.now());

  /// Generates challenge config deterministically from the date.
  static DailyChallengeConfig generateChallengeForDate(DateTime date) {
    // Integer seed from date: e.g. 20260317
    final dateSeed = date.year * 10000 + date.month * 100 + date.day;

    // Vary difficulty across the week (Mon=1 easy → Sun=7 hard)
    final weekday = date.weekday; // 1-7
    final baseScore = 200 + weekday * 50; 
    final cartoons = weekday >= 5 ? 8 : 4; // More on weekends
    final lines = weekday % 3 == 0 ? 10 + weekday : 0; // Every 3 days has line clearing goal
    final combos = weekday % 4 == 0 ? 3 : 0; // Every 4 days has combo goal
    final perfectFits = weekday % 5 == 0 ? 5 : 0; // Every 5 days has perfection goal
    
    final obstacles = 0;

    return DailyChallengeConfig(
      seed: dateSeed,
      targetScore: baseScore,
      targetCartoons: cartoons,
      targetLines: lines,
      targetCombos: combos,
      targetPerfectFits: perfectFits,
      obstacles: obstacles,
      coinReward: 100 + (weekday * 10),
      gemReward: weekday >= 6 ? 5 : 2,
    );
  }

  /// Generates today's challenge config deterministically from the date.
  static DailyChallengeConfig generateTodayChallenge() {
    return generateChallengeForDate(DateTime.now());
  }

  /// Returns true if the challenge for the given date has been completed.
  Future<bool> isCompleted(DateTime date) async {
    if (_uid == null) return false;
    final key = dateToKey(date);
    try {
      final snap = await _db.child('Users/${_uid!}/dailyChallenge/$key').get();
      return snap.exists && snap.value == true;
    } catch (e) {
      debugPrint('DailyChallengeService.isCompleted error: $e');
      return false;
    }
  }

  /// Returns true if today's challenge has already been completed.
  Future<bool> isTodayCompleted() => isCompleted(DateTime.now());

  /// Marks the challenge for the given date as completed.
  Future<void> markCompleted(DateTime date) async {
    if (_uid == null) return;
    final key = dateToKey(date);
    try {
      await _db.child('Users/${_uid!}/dailyChallenge/$key').set(true);
    } catch (e) {
      debugPrint('DailyChallengeService.markCompleted error: $e');
    }
  }

  /// Marks today's challenge as completed.
  Future<void> markTodayCompleted() => markCompleted(DateTime.now());

  /// Fetches completion status for an entire month in one query.
  Future<Map<String, bool>> getCompletionStatusForMonth(DateTime month) async {
    if (_uid == null) return {};
    final startKey = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    final endKey = '${month.year}-${month.month.toString().padLeft(2, '0')}-31';

    try {
      final snap = await _db
          .child('Users/${_uid!}/dailyChallenge')
          .orderByKey()
          .startAt(startKey)
          .endAt(endKey)
          .get();

      if (snap.exists && snap.value != null) {
        // Handle both Map and List cases from Firebase
        if (snap.value is Map) {
          final Map<dynamic, dynamic> values = snap.value as Map;
          return values.map((key, value) => MapEntry(key.toString(), value == true));
        }
      }
      return {};
    } catch (e) {
      debugPrint('DailyChallengeService.getCompletionStatusForMonth error: $e');
      return {};
    }
  }
}
