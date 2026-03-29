// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/developer_guide_screen.dart';
import 'screens/about_screen.dart';
import 'utils/constants.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/developer': (context) => const DeveloperGuideScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
