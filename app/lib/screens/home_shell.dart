import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'applications_screen.dart';
import 'coach_screen.dart';
import 'deck_screen.dart';
import 'interviews_screen.dart';
import 'profile_screen.dart';

// Shell with frosted white tab. Bumble tab pattern.

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;
  final pages = const [
    DeckScreen(),
    ApplicationsScreen(),
    InterviewsScreen(),
    CoachScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: idx, children: pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: const Border(top: BorderSide(color: line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Row(
                  children: [
                    _tab(0, Icons.style_outlined, Icons.style, 'Deck', null, false),
                    _tab(1, Icons.article_outlined, Icons.article, 'Apps', '4', false),
                    _tab(2, Icons.event_available_outlined, Icons.event_available, 'Interviews', '3', false),
                    _tab(3, Icons.phone_outlined, Icons.phone_in_talk, 'Coach', null, true),
                    _tab(4, Icons.person_outline, Icons.person, 'Profile', null, false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData idle, IconData active, String label, String? badge, bool dot) {
    final sel = i == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => idx = i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? tint : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(sel ? active : idle, color: sel ? navy : muted, size: 22),
                  if (badge != null)
                    Positioned(
                      right: -12,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(10)),
                        child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (dot && !sel)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: sky, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(color: sel ? navy : muted, fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
