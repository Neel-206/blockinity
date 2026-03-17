import 'package:blockinity/Services/daily_reward_service.dart';
import 'package:blockinity/Services/player_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class PlayerController extends GetxController {
  final PlayerService _playerService = PlayerService();
  final DailyRewardService _dailyRewardService = DailyRewardService();

  final RxInt highestScore = 0.obs;
  final RxInt coins = 0.obs;
  final RxInt gems = 0.obs;
  final RxInt blocksCleared = 0.obs;
  final RxInt unlockedLevel = 0.obs;

  // ── Spin / streak reactive state ──────────────────────────────────────────
  final RxBool  canSpin          = true.obs;   // false when 24 h not elapsed
  final RxInt   streakDayIndex   = 0.obs;      // 0-6, which day tile is active
  final RxInt   secondsUntilNext = 0.obs;      // countdown seconds

  @override
  void onInit() {
    super.onInit();
    _loadData();
    _loadSpinState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadData();
        _loadSpinState();
      } else {
        _resetData();
      }
    });
  }

  void _resetData() {
    highestScore.value = 0;
    coins.value = 0;
    gems.value = 0;
    blocksCleared.value = 0;
    unlockedLevel.value = 0;
  }

  Future<void> _loadData() async {
    final data = await _playerService.getPlayerData();
    if (data != null) {
      highestScore.value = data['highestScore'] ?? 0;
      coins.value = data['coins'] ?? 0;
      gems.value = data['gems'] ?? 0;
      blocksCleared.value = data['blocksCleared'] ?? 0;
      unlockedLevel.value = data['unlockedLevel'] ?? 0;
    }
  }

  void addScore(int newScore) {
    if (newScore > highestScore.value) {
      highestScore.value = newScore;
      _saveData({'highestScore': highestScore.value});
    }
  }

  void addCoins(int amount) {
    coins.value += amount;
    _saveData({'coins': coins.value});
  }

  void addGems(int amount) {
    gems.value += amount;
    _saveData({'gems': gems.value});
  }

  void addBlocksCleared(int amount) {
    blocksCleared.value += amount;
    _saveData({'blocksCleared': blocksCleared.value});
  }

  void completeLevel(int level) {
    if (level > unlockedLevel.value) {
      unlockedLevel.value = level;
      _saveData({'unlockedLevel': unlockedLevel.value});
    }
    // Award gems for completing level
    addGems(1);

    // Complete world bonus (every 20 levels = 1 world)
    if (level % 20 == 0) {
      addGems(5);
    }
  }

  void claimDailyReward(int day) {
    if (day == 1) addCoins(50);
    if (day == 2) addCoins(100);
    if (day == 3) addGems(2);
  }

  // ── Spin flow ─────────────────────────────────────────────────────────────

  /// Loads initial spin state from Firebase (seconds remaining + streak day).
  Future<void> _loadSpinState() async {
    secondsUntilNext.value = await _dailyRewardService.secondsUntilNextSpin();
    streakDayIndex.value   = await _dailyRewardService.currentStreakDayIndex();
    canSpin.value          = secondsUntilNext.value == 0;
  }

  /// Full spin flow:
  ///   1. Check 24 h limit
  ///   2. Give spin (wheel) reward
  ///   3. Update & advance streak
  ///   4. Give daily streak reward
  ///   5. Save everything to Firebase
  ///
  /// Returns [SpinResult] — caller uses .allowed to know if spin went through.
  Future<SpinResult> performSpin(String wheelRewardLabel) async {
    // Step 1 – check 24 h limit & record spin in Firebase
    final result = await _dailyRewardService.attemptSpin();

    if (!result.allowed) {
      secondsUntilNext.value = result.secondsUntilNext;
      canSpin.value = false;
      return result;
    }

    // Step 2 – give wheel (spin) reward
    _applyWheelReward(wheelRewardLabel);

    // Step 3 & 4 – update streak display and give streak reward
    streakDayIndex.value   = result.streakDayIndex;
    secondsUntilNext.value = 86400;
    canSpin.value          = false;
    _applyStreakReward(result.streakDayIndex);

    // Step 5 – Firebase is already updated inside attemptSpin()
    return result;
  }

  void _applyWheelReward(String label) {
    if (label.contains('Coins')) {
      addCoins(int.tryParse(label.split(' ')[0]) ?? 50);
    } else if (label.contains('Gems') || label == 'Mega') {
      addGems(label == 'Mega' ? 10 : (int.tryParse(label.split(' ')[0]) ?? 1));
    }
  }

  void _applyStreakReward(int dayIndex) {
    final i = dayIndex.clamp(0, StreakRewardConfig.coins.length - 1);
    if (StreakRewardConfig.coins[i] > 0) addCoins(StreakRewardConfig.coins[i]);
    if (StreakRewardConfig.gems[i]  > 0) addGems(StreakRewardConfig.gems[i]);
  }

  void _saveData(Map<String, dynamic> data) {
    _playerService.updatePlayerData(data);
  }
}
