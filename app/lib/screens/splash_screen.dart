import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Splash. Bumble zero state plus Luma glow, kept flat white.

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
