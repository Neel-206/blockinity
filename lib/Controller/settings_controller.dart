import 'package:get/get.dart';

class SettingsController extends GetxController {
  final RxBool soundEffects = true.obs;
  final RxBool music = false.obs;
  final RxBool vibration = true.obs;
  
  final RxBool dailyRewardsNotify = true.obs;
  final RxBool eventUpdatesNotify = true.obs;

  void toggleSound(bool value) => soundEffects.value = value;
  void toggleMusic(bool value) => music.value = value;
  void toggleVibration(bool value) => vibration.value = value;
  void toggleDailyRewards(bool value) => dailyRewardsNotify.value = value;
  void toggleEventUpdates(bool value) => eventUpdatesNotify.value = value;
}
