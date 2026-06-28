import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تنفيذ أمر adb reverse تلقائياً إذا كان التطبيق يعمل بوضع الـ Debug وعلى أندرويد
  if (Platform.isAndroid) {
    try {
      // محاولة تشغيل الأمر مباشرة من داخل نظام الموبايل
      await Process.run('adb', ['reverse', 'tcp:8000', 'tcp:8000']);
      print('🚀 ADB Reverse executed successfully automatically!');
    } catch (e) {
      print('⚠️ ADB Reverse auto-failed: $e (This is normal if not connected via USB)');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITE System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}