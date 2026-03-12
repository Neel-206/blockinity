import 'package:blockinity/routes/app_routes.dart';
import 'package:blockinity/ui/forgot_password.dart';
import 'package:blockinity/ui/game_screen.dart';
import 'package:blockinity/ui/level_screen.dart';
import 'package:blockinity/ui/main_screens.dart';
import 'package:blockinity/ui/login_screen.dart';
import 'package:blockinity/ui/ragister_screen.dart';
import 'package:blockinity/ui/splase_screen.dart';
import 'package:blockinity/ui/world_screen.dart';
import 'package:get/get.dart';

class AppPages extends AppRoutes{
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplaseScreen()),
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => RagisterScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPassword()),
    GetPage(name: AppRoutes.home, page: () => HomeScreen()),
    GetPage(name: AppRoutes.world, page: () => WorldScreen()),
    GetPage(name: AppRoutes.game, page: () => GameScreen()),  
    GetPage(name: AppRoutes.levels, page: () => LevelScreen()),
  ];
}