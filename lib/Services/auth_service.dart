import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<User?> login({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null) {
        try {
          await _db.child('Users/${user.uid}/profile').update({
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (e) {
          debugPrint('Failed to update last login: $e');
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<User?> register({required String name, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        try {
          await user.updateDisplayName(name);
        } catch (_) {}
        
        // Save user profile to database under "Users" node
        try {
          await _db.child('Users/${user.uid}/profile').set({
            'name': name,
            'email': email,
            'provider': 'email',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (e) {
          debugPrint('Failed to save user profile: $e');
        }

        try {
          await user.sendEmailVerification();
        } catch (_) {}
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      // If sign-out of one provider fails, still attempt to sign out auth.
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Password reset failed');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Google ID Token is null. Please check your Firebase/Google configuration.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Google sign-in failed');

      // Check if user exists to prevent overwriting existing data and ensure createdAt is set.
      try {
        final profileRef = _db.child('Users/${user.uid}/profile');
        final snapshot = await profileRef.get();

        if (snapshot.exists) {
          await profileRef.update({
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          await profileRef.set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'provider': 'google',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        debugPrint('Failed to save user profile: $e');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Google sign-in failed');
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<bool> userExistsInDatabase(String uid) async {
    try {
      final snapshot = await _db.child('Users/$uid/profile').get();
      return snapshot.exists;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }
}

  
