import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Per-day streak reward config (index 0 = streak day 1, index 6 = day 7/MEGA).
class StreakRewardConfig {
  static const List<int> coins = [50,  100, 150, 0,   0,   300, 0  ];
  static const List<int> gems  = [0,   0,   0,   2,   5,   0,   10 ];
  static const List<String> labels = [
    '50 Coins', '100 Coins', '150 Coins',
    '2 Gems',   '5 Gems',    '300 Coins', 'MEGA 🎁',
  ];
}

/// Result returned after a spin attempt.
class SpinResult {
  /// Whether the spin was allowed (24 h not elapsed → false).
  final bool allowed;

  /// Seconds remaining until next spin (0 if allowed).
  final int secondsUntilNext;

  /// Current streak day index 0-6 (only valid when allowed = true).
  final int streakDayIndex;

  const SpinResult({
    required this.allowed,
    required this.secondsUntilNext,
    required this.streakDayIndex,
  });
}

class DailyRewardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? get _uid => _auth.currentUser?.uid;
  DatabaseReference get _spinRef => _db.child('Users/${_uid!}/spinData');

  Future<SpinResult> attemptSpin() async {
    if (_uid == null) {
      return const SpinResult(allowed: false, secondsUntilNext: 0, streakDayIndex: 0);
    }

    try {
      final snap = await _spinRef.get();
      final data = snap.exists && snap.value != null
          ? Map<String, dynamic>.from(snap.value as Map)
          : <String, dynamic>{};

      final lastSpinMs  = (data['lastSpinTime'] as int?) ?? 0;
      int   streakCount = (data['streakCount']  as int?) ?? 0;

      final now         = DateTime.now();
      final lastSpin    = DateTime.fromMillisecondsSinceEpoch(lastSpinMs);
      final elapsed     = now.difference(lastSpin);

      if (lastSpinMs != 0 && elapsed.inSeconds < 86400) {
        // 24 h not passed yet
        return SpinResult(
          allowed: false,
          secondsUntilNext: 86400 - elapsed.inSeconds,
          streakDayIndex: streakCount % 7,
        );
      }

      // Reset streak if more than 48 h have passed (missed a day)
      if (lastSpinMs != 0 && elapsed.inHours >= 48) {
        streakCount = 0;
      }

      final newStreakDayIndex = streakCount % 7;
      final newStreakCount    = streakCount + 1;

      // Persist to Firebase
      await _spinRef.update({
        'lastSpinTime': now.millisecondsSinceEpoch,
        'streakCount' : newStreakCount,
      });

      return SpinResult(
        allowed: true,
        secondsUntilNext: 86400,
        streakDayIndex: newStreakDayIndex,
      );
    } catch (e) {
      debugPrint('DailyRewardService.attemptSpin error: $e');
      return const SpinResult(allowed: false, secondsUntilNext: 0, streakDayIndex: 0);
    }
  }

  /// Loads how many seconds remain until the next spin (0 = can spin now).
  Future<int> secondsUntilNextSpin() async {
    if (_uid == null) return 0;
    try {
      final snap = await _spinRef.child('lastSpinTime').get();
      if (!snap.exists || snap.value == null) return 0;
      final lastSpinMs = snap.value as int;
      final elapsed    = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastSpinMs));
      final remaining  = 86400 - elapsed.inSeconds;
      return remaining < 0 ? 0 : remaining;
    } catch (e) {
      debugPrint('DailyRewardService.secondsUntilNextSpin error: $e');
      return 0;
    }
  }

  /// Loads the current streak count (0-based day index = streakCount % 7).
  Future<int> currentStreakDayIndex() async {
    if (_uid == null) return 0;
    try {
      final snap = await _spinRef.child('streakCount').get();
      if (!snap.exists || snap.value == null) return 0;
      return ((snap.value as int) % 7);
    } catch (e) {
      return 0;
    }
  }
}
