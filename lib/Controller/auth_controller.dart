import 'package:blockinity/Services/auth_service.dart';
import 'package:blockinity/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  Rx<User?> user = Rx<User?>(null);
  RxBool isLoading = false.obs;

  
  @override
  void onInit() {
    user.bindStream(_authService.authStateChanges);
    super.onInit();
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({required String name, required String email, required String password}) async {
    try {
      isLoading.value = true;
      await _authService.register(email: email, password: password, name: name);
    } catch (e) {
      Get.snackbar('Registration Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> forgotPassword({required String email}) async {
    await _authService.forgotPassword(email: email);
  }

 Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      await _authService.signInWithGoogle();

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        "Google Sign-In Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
}
