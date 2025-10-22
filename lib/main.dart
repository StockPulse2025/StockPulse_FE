import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(ApiService())),
      ],
      child: const MyApp(),
    ),
  );
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