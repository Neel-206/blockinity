import 'package:blockinity/theme/app_theme.dart';
import 'package:blockinity/binding/Inistial_biniding.dart';
import 'package:blockinity/firebase_options.dart';
import 'package:blockinity/routes/app_pages.dart';
import 'package:blockinity/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      supportedLocales: const [Locale('en')],
      initialRoute: AppRoutes.login,
      getPages: AppPages.pages,
      initialBinding: InistialBiniding(),
    );
  }
}
