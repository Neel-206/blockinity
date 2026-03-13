import 'package:blockinity/Controller/auth_controller.dart';
import 'package:blockinity/Controller/level_controller.dart';
import 'package:get/get.dart';

class InistialBiniding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<LevelController>(LevelController(), permanent: true);
  }
}