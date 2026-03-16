import 'package:blockinity/Services/player_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class PlayerController extends GetxController {
  final PlayerService _playerService = PlayerService();

  final RxInt highestScore = 0.obs;
  final RxInt coins = 0.obs;
  final RxInt gems = 0.obs;
  final RxInt blocksCleared = 0.obs;
  final RxInt unlockedLevel = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadData();
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

  void _saveData(Map<String, dynamic> data) {
    _playerService.updatePlayerData(data);
  }
}
