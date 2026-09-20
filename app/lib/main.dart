import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hackthon2/pages/theme/apptheme.dart';
import 'package:hackthon2/service/medicine_reminder_service.dart';

import 'pages/splashscreen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await MedicineReminderService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SEVA',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}