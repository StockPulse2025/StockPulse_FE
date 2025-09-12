import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications/notification_center_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockPulse',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
    );
  }
}