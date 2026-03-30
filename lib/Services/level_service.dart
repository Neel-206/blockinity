import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class LevelService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;

  /// Fetches the last unlocked level for the current user.
  /// Default is 0 (World 1, Level 1 is levelNum 1).
  Future<int> getUnlockedLevel() async {
    final user = currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _db.child('Users/${user.uid}/progress/unlockedLevel').get();
      if (snapshot.exists) {
        return int.tryParse(snapshot.value.toString()) ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching level progress: $e');
    }
    return 0;
  }

  /// Updates the unlocked level if the new level is higher than the current one.
  Future<void> updateUnlockedLevel(int levelNum) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Direct update is generally safer and faster. 
      // The controller already checks if it's higher than its local state.
      await _db.child('Users/${user.uid}/progress').update({
        'unlockedLevel': levelNum,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Also update the legacy path used by PlayerController for backward consistency
      await _db.child('Users/${user.uid}').update({
        'unlockedLevel': levelNum,
      });
    } catch (e) {
      debugPrint('Error updating level progress: $e');
    }
  }

  /// Stream to listen to level progress changes in real-time.
  Stream<DatabaseEvent> get levelProgressStream {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return _db.child('Users/${user.uid}/progress/unlockedLevel').onValue;
  }
}
