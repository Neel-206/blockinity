import 'package:blockinity/Services/level_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LevelController extends GetxController {
  final LevelService _levelService = LevelService();
  
  // Stores the highest level number unlocked (e.g., 5 means 5 levels completed)
  final RxInt unlockedLevel = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialProgress();
    
    // Listen to Auth changes to reload progress when user logs in/out
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadInitialProgress();
      } else {
        unlockedLevel.value = 0;
      }
    });
  }

  Future<void> _loadInitialProgress() async {
    isLoading.value = true;
    final progress = await _levelService.getUnlockedLevel();
    unlockedLevel.value = progress;
    isLoading.value = false;
  }

  /// Called when a level is cleared. 
  /// If the cleared level is the highest so far, updates persistent storage.
  Future<void> completeLevel(int levelNum) async {
    if (levelNum > unlockedLevel.value) {
      unlockedLevel.value = levelNum;
      await _levelService.updateUnlockedLevel(levelNum);
    }
  }

  /// Helper to get current level progress for a specific world.
  /// Each world has 20 levels.
  int getProgressForWorld(int worldIndex) {
    // world 0: levels 1-20
    // world 1: levels 21-40
    int startLevel = (worldIndex * 20);
    if (unlockedLevel.value <= startLevel) return 0;
    
    int progress = unlockedLevel.value - startLevel;
    return progress > 20 ? 20 : progress;
  }
}
