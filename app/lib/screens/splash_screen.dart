import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'google_login_screen.dart';

// Splash. Bumble zero state plus Luma glow, kept flat white.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GoogleLoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OwlBadge(size: 92),
            SizedBox(height: 20),
            Text(
              'dreamJob',
              style: TextStyle(color: ink, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.2),
            ),
            SizedBox(height: 8),
            Text(
              'SWIPE  •  MATCH  •  HIRED',
              style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
