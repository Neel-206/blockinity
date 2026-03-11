import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInit;

  Future<void> _ensureGoogleInitialized() async {
    _googleInit ??= _googleSignIn.initialize();
    await _googleInit;
  }
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<User?> login({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
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
      await _ensureGoogleInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Google sign-in failed');

      // Save user profile if new/updated — ignore DB errors but log them.
      try {
        await _db.child('users/${user.uid}/profile').update({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'provider': 'google',
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        // ignore: avoid_print
        print('Failed to save user profile: $e');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Google sign-in failed');
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }
}

  

