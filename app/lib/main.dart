import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() => runApp(const DreamJobApp());

class DreamJobApp extends StatelessWidget {
  const DreamJobApp({super.key});
  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: navy, brightness: Brightness.light),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ink,
      ),
    );
    return MaterialApp(
      title: 'dreamJob',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
