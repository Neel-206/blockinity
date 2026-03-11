import 'package:blockinity/routes/app_routes.dart';
import 'package:blockinity/ui/forgot_password.dart';
import 'package:blockinity/ui/login_screen.dart';
import 'package:blockinity/ui/ragister_screen.dart';
import 'package:blockinity/ui/splase_screen.dart';
import 'package:get/get.dart';

class AppPages extends AppRoutes{
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplaseScreen()),
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => RagisterScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPassword()),
    GetPage(name: AppRoutes.home, page: () => SplaseScreen()),
  ];
}