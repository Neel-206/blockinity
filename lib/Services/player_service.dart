import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class PlayerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;

  Future<Map<dynamic, dynamic>?> getPlayerData() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final snapshot = await _db.child('Users/${user.uid}').get();
      if (snapshot.exists) {
        return snapshot.value as Map<dynamic, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getting player data: $e');
    }
    return null;
  }

  Future<void> updatePlayerData(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _db.child('Users/${user.uid}').update(data);
    } catch (e) {
      debugPrint('Error updating player data: $e');
    }
  }
}
