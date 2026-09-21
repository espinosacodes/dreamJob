import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const DreamJobApp());

// Tokens. White flat base from Bumble and Luma, blues only as accents.
const _ink = Color(0xFF0E1E2E);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE5EDF3);
const _wash = Color(0xFFF4F7FA);
const _tint = Color(0xFFE8F1F7);
const _navy = Color(0xFF012A4A);
const _blue = Color(0xFF01497C);
const _sky = Color(0xFF2C7DA0);
const _skySoft = Color(0xFFA9D6E5);
const _amberBg = Color(0xFFFFF6E0);
const _amberLine = Color(0xFFEFD48A);
const _amberInk = Color(0xFF8A5A00);
const _green = Color(0xFF1A7F4E);
const _greenBg = Color(0xFFE6F4EC);

class DreamJobApp extends StatelessWidget {
  const DreamJobApp({super.key});
  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: _navy, brightness: Brightness.light),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _ink,
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

// Shared primitives

class OwlBadge extends StatelessWidget {
  final double size;
  const OwlBadge({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.30),
        color: _navy,
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.62,
          height: size * 0.52,
          child: CustomPaint(painter: _OwlPainter()),
        ),
      ),
    );
  }
}

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final navy = Paint()..color = _navy;
    final eyeR = size.width * 0.24;
    final leftC = Offset(size.width * 0.26, size.height * 0.44);
    final rightC = Offset(size.width * 0.74, size.height * 0.44);
    canvas.drawCircle(leftC, eyeR, white);
    canvas.drawCircle(rightC, eyeR, white);
    canvas.drawCircle(leftC, eyeR * 0.48, navy);
    canvas.drawCircle(rightC, eyeR * 0.48, navy);
    canvas.drawCircle(
      leftC + Offset(eyeR * 0.18, -eyeR * 0.18),
      eyeR * 0.14,
      white,
    );
    canvas.drawCircle(
      rightC + Offset(eyeR * 0.18, -eyeR * 0.18),
      eyeR * 0.14,
      white,
    );
    final frame = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    canvas.drawCircle(leftC, eyeR * 1.08, frame);
    canvas.drawCircle(rightC, eyeR * 1.08, frame);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.40),
      Offset(size.width * 0.52, size.height * 0.40),
      frame,
    );
    final beak = Path()
      ..moveTo(size.width * 0.44, size.height * 0.72)
      ..lineTo(size.width * 0.56, size.height * 0.72)
      ..lineTo(size.width * 0.50, size.height * 0.84)
      ..close();
    canvas.drawPath(beak, Paint()..color = _skySoft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FrostedTop extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  const FrostedTop({super.key, required this.title, this.leading, this.actions});
  @override
  Size get preferredSize => const Size.fromHeight(52);
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            border: const Border(bottom: BorderSide(color: _line)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 52,
            leadingWidth: 40,
            titleSpacing: 4,
            leading: leading,
            title: title,
            actions: actions,
          ),
        ),
      ),
    );
  }
}

class CircleBack extends StatelessWidget {
  const CircleBack({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _ink, size: 16),
      ),
    );
  }
}

class PrimaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const PrimaryPill({super.key, required this.label, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

class SecondaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SecondaryPill({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: _line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class WashField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? prefix;
  const WashField({super.key, this.controller, required this.hint, this.prefix});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _ink, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _muted),
        prefixIcon: prefix == null ? null : Icon(prefix, color: _muted),
        filled: true,
        fillColor: _wash,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class DjCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DjCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const StatusPill({super.key, required this.label, required this.fg, required this.bg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class SectionHead extends StatelessWidget {
  final String title;
  final String? sub;
  const SectionHead({super.key, required this.title, this.sub});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, style: const TextStyle(color: _muted, fontSize: 13, height: 1.4)),
        ],
      ],
    );
  }
}

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
              style: TextStyle(color: _ink, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.2),
            ),
            SizedBox(height: 8),
            Text(
              'SWIPE  •  MATCH  •  HIRED',
              style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Login. Only Google. Luma phone pattern on white.

class GoogleLoginScreen extends StatelessWidget {
  const GoogleLoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: _wash, shape: BoxShape.circle, border: Border.all(color: _line)),
                child: const Icon(Icons.mail_outline, color: _blue, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to dreamJob',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect Gmail once. The agent reads the OTP code for you and finishes each application.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              DjCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                            child: Text('G', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gmail for OTP', style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('Read only. Codes only. Nothing else.', style: TextStyle(color: _muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        const StatusPill(label: 'AUTO', fg: _navy, bg: _tint),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryPill(
                      label: 'Continue with Google',
                      onTap: _noop,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Only Google. No Apple. No Line. 2FA by mail or SMS on the next step.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: _blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OAuth with gmail.readonly scope. No password stored. Revoke anytime in Profile.',
                        style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Real entry for prototype. Secondary to keep primary pure.
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GmailConnectScreen()),
                  ),
                  child: const Text('Set up agent', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _noop() {}
}

// Gmail plus 2FA setup. Luma grouped rows pattern.

class GmailConnectScreen extends StatefulWidget {
  const GmailConnectScreen({super.key});
  @override
  State<GmailConnectScreen> createState() => _GmailConnectScreenState();
}

class _GmailConnectScreenState extends State<GmailConnectScreen> {
  bool gmail = true;
  String channel = 'mail';
  final phoneCtrl = TextEditingController(text: '+57 300 000 0000');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        leading: CircleBack(),
        title: Text('Agent setup', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHead(
            title: 'Let the agent apply',
            sub: 'Verification codes are the blocker. Gmail automation removes it.',
          ),
          const SizedBox(height: 16),
          DjCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: _blue, size: 18),
                    SizedBox(width: 8),
                    Text('Auto apply agent', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'When a company asks for a code, the agent extracts it from Gmail and completes the form. You keep swiping.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, color: _blue, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Gmail connected', style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: gmail,
                        activeColor: _blue,
                        onChanged: (v) => setState(() => gmail = v),
                      ),
                    ],
                  ),
                ),
                if (!gmail)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _amberBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amberLine)),
                    child: const Text(
                      'Without Gmail the agent pauses on every OTP and asks you manually.',
                      style: TextStyle(color: _amberInk, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('2FA CHANNEL', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _line)),
            child: Column(
              children: [
                _radioRow('By mail', 'Fastest. Agent reads it in seconds.', Icons.mail_outline, channel == 'mail', () => setState(() => channel = 'mail'), true),
                const Divider(height: 1, color: _line, indent: 16, endIndent: 16),
                _radioRow('By SMS', 'Agent shows a prompt and you paste it.', Icons.sms_outlined, channel == 'sms', () => setState(() => channel = 'sms'), false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (channel == 'sms')
            WashField(controller: phoneCtrl, hint: 'Phone number', prefix: Icons.phone_outlined)
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.bolt_outlined, color: _navy, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Mail is recommended. Zero taps during a swipe session.', style: TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          PrimaryPill(
            label: 'Connect and enter',
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (_) => false,
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('OAuth Google  •  gmail.readonly  •  revocable', style: TextStyle(color: _muted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _radioRow(String title, String sub, IconData icon, bool selected, VoidCallback onTap, bool first) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: first ? const Radius.circular(24) : Radius.zero,
        bottom: first ? Radius.zero : const Radius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: selected ? _tint : _wash, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: selected ? _navy : _muted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(sub, style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _navy : Colors.transparent,
                border: Border.all(color: selected ? _navy : _line, width: 2),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }
}

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
              border: const Border(top: BorderSide(color: _line)),
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
                color: sel ? _tint : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(sel ? active : idle, color: sel ? _navy : _muted, size: 22),
                  if (badge != null)
                    Positioned(
                      right: -12,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(10)),
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
                        decoration: BoxDecoration(color: _sky, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(color: sel ? _navy : _muted, fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// Deck. Job cards on white, Bumble card discipline.

class JobItem {
  final String title;
  final String company;
  final String mono;
  final String photo;
  final String location;
  final String comp;
  final String compProv;
  final String posted;
  final List<String> stack;
  final List<String> bullets;
  final List<String> reasons;
  final String? warning;
  const JobItem({
    required this.title,
    required this.company,
    required this.mono,
    required this.photo,
    required this.location,
    required this.comp,
    required this.compProv,
    required this.posted,
    required this.stack,
    required this.bullets,
    required this.reasons,
    this.warning,
  });
}

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});
  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> with SingleTickerProviderStateMixin {
  int top = 0;
  double drag = 0;
  bool showQueued = false;
  late final AnimationController press;
  double pressScale = 1.0;

  final jobs = const [
    JobItem(
      title: 'Senior Backend Engineer',
      company: 'Rappi',
      mono: 'R',
      photo: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80&auto=format&fit=crop',
      location: 'Bogota  •  Hybrid 2 days  •  Calle 93 office',
      comp: 'USD 80k to 110k',
      compProv: 'posted',
      posted: '2 days ago',
      stack: ['Go', 'Kubernetes', 'Postgres', 'gRPC', 'Redis', '+2'],
      bullets: ['Own the payments ingestion pipeline', '5 person platform team, no on call', 'Series F, 5000 people'],
      reasons: ['Go plus Kubernetes on your list', 'Bogota hybrid accepted', 'Above comp floor'],
    ),
    JobItem(
      title: 'Frontend Engineer',
      company: 'Google',
      mono: 'G',
      photo: 'https://images.unsplash.com/photo-1573164713988-8665fc963095?w=800&q=80&auto=format&fit=crop',
      location: 'Bogota  •  Hybrid  •  Calle 100 campus',
      comp: 'USD 120k to 160k',
      compProv: 'posted',
      posted: '1 day ago',
      stack: ['TypeScript', 'Angular', 'RxJS', 'GCP'],
      bullets: ['Build advertiser console used daily', 'Large team, strong mentorship', 'L4 band, visa support'],
      reasons: ['TypeScript on your list', 'Hybrid in Bogota', 'Top comp band'],
      warning: 'Title says Hybrid, body says 3 days in office',
    ),
    JobItem(
      title: 'Platform Engineer',
      company: 'Nubank',
      mono: 'N',
      photo: 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&q=80&auto=format&fit=crop',
      location: 'Remote  •  LATAM  •  Sao Paulo hub',
      comp: 'USD 90k to 130k',
      compProv: 'estimated',
      posted: '3 days ago',
      stack: ['Go', 'AWS', 'Terraform', 'Docker'],
      bullets: ['Build the internal developer platform', '200 engineers as users', 'No visa needed'],
      reasons: ['Strong Go match', 'Remote LATAM', 'Comp in range'],
    ),
    JobItem(
      title: 'Staff Engineer, Data',
      company: 'Platzi',
      mono: 'P',
      photo: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80&auto=format&fit=crop',
      location: 'Remote  •  LATAM  •  Bogota meetups',
      comp: 'No range posted',
      compProv: '',
      posted: '5 days ago',
      stack: ['Python', 'Postgres', 'Kafka'],
      bullets: ['Lead data ingestion', 'Greenfield zero to one', 'Reports to CTO'],
      reasons: ['Python on want list', 'Remote LATAM', 'Staff level'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    press = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  }

  @override
  void dispose() {
    press.dispose();
    super.dispose();
  }

  void _swipe(bool right) {
    if (right) {
      setState(() => showQueued = true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => showQueued = false);
      });
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 4),
          content: const Text('Skipped. Undo available for 10 seconds.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () => setState(() => top = (top - 1) % jobs.length),
          ),
        ),
      );
    }
    setState(() {
      top = (top + 1) % jobs.length;
      drag = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final j = jobs[top];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: FrostedTop(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: OwlBadge(size: 26)),
        ),
        title: Text(
          '${top + 1} of ${jobs.length}  •  Daily deck',
          style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: StatusPill(label: 'STRONG', fg: _navy, bg: _tint)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(() => drag += d.delta.dx),
                    onHorizontalDragEnd: (_) {
                      if (drag > 90) {
                        _swipe(true);
                      } else if (drag < -90) {
                        _swipe(false);
                      }
                      setState(() => drag = 0);
                    },
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetail(job: j))),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      transform: Matrix4.identity()
                        ..translate(drag * 0.25)
                        ..rotateZ(drag * 0.0006),
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => pressScale = 0.985),
                        onTapUp: (_) => setState(() => pressScale = 1.0),
                        onTapCancel: () => setState(() => pressScale = 1.0),
                        child: AnimatedScale(
                          scale: pressScale,
                          duration: const Duration(milliseconds: 180),
                          child: DjCard(
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Expanded(
                                          child: Container(
                                            height: 3,
                                            margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
                                            decoration: BoxDecoration(
                                              color: i == 0 ? _navy : _line,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            j.photo,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 180,
                                              color: _tint,
                                              child: const Center(child: Icon(Icons.business_outlined, color: _navy, size: 32)),
                                            ),
                                          ),
                                          Positioned(
                                            left: 10,
                                            bottom: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.62), borderRadius: BorderRadius.circular(20)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.verified, color: Colors.white, size: 13),
                                                  const SizedBox(width: 4),
                                                  Text('${j.company} office', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(12)),
                                          child: Center(
                                            child: Text(j.mono, style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w800)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(j.company, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.verified, color: _blue, size: 15),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(j.posted, style: const TextStyle(color: _muted, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      j.title,
                                      style: const TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.1),
                                    ),
                                    const SizedBox(height: 10),
                                    _meta(Icons.public_outlined, j.location),
                                    const SizedBox(height: 6),
                                    _meta(
                                      Icons.payments_outlined,
                                      j.compProv.isEmpty ? j.comp : '${j.comp}  •  ${j.compProv}',
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: j.stack.map((s) {
                                        final hot = s == 'Go' || s == 'Kubernetes';
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: hot ? _tint : _wash,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: hot ? _skySoft : _line),
                                          ),
                                          child: Text(
                                            s,
                                            style: TextStyle(color: hot ? _navy : _muted, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        children: j.bullets
                                            .map(
                                              (b) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle)),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(b, style: const TextStyle(color: _ink, fontSize: 13, height: 1.4))),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('WHY THIS CARD', style: TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                                          const SizedBox(height: 4),
                                          Text(j.reasons.join('  •  '), style: const TextStyle(color: _navy, fontSize: 12, height: 1.4)),
                                        ],
                                      ),
                                    ),
                                    if (j.warning != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: _amberBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amberLine)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, color: _amberInk, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text(j.warning!, style: const TextStyle(color: _amberInk, fontSize: 11, height: 1.4))),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(child: SecondaryPill(label: 'Skip', onTap: () => _swipe(false))),
                                        const SizedBox(width: 10),
                                        Expanded(child: PrimaryPill(label: 'Apply', onTap: () => _swipe(true), icon: Icons.arrow_forward)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    const Center(child: Text('Tap card for full description', style: TextStyle(color: _muted, fontSize: 10))),
                                  ],
                                ),
                                if (drag > 40)
                                  Positioned(
                                    top: 44,
                                    left: 8,
                                    child: Transform.rotate(
                                      angle: -0.12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _navy, width: 2.5), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('APPLY', style: TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 18)),
                                      ),
                                    ),
                                  ),
                                if (drag < -40)
                                  Positioned(
                                    top: 44,
                                    right: 8,
                                    child: Transform.rotate(
                                      angle: 0.12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _muted, width: 2.5), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('SKIP', style: TextStyle(color: _muted, fontWeight: FontWeight.w900, fontSize: 18)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleBtn(Icons.undo, _muted, () => setState(() => top = (top - 1) % jobs.length)),
                    _circleBtn(Icons.close, _navy, () => _swipe(false), big: true),
                    _circleBtn(Icons.star_outline, _sky, () => _swipe(true)),
                    _circleBtn(Icons.favorite, _sky, () => _swipe(true), big: true),
                    _circleBtn(Icons.bookmark_border, _muted, () {}),
                  ],
                ),
              ),
            ],
          ),
          if (showQueued) _queuedDialog(context),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _muted, size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: _muted, fontSize: 12))),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap, {bool big = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: big ? 60 : 48,
        height: big ? 60 : 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _line),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
        ),
        child: Icon(icon, color: color, size: big ? 26 : 20),
      ),
    );
  }

  // Bumble thanks pattern on white.
  Widget _queuedDialog(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.28),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OwlBadge(size: 56),
                  const SizedBox(height: 14),
                  const Text('Queued for tailoring', textAlign: TextAlign.center, style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'The agent is tailoring your resume and cover letter. Review before anything is sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 4, child: LinearProgressIndicator(color: _navy, backgroundColor: _line)),
                  const SizedBox(height: 16),
                  PrimaryPill(label: 'View in Apps', onTap: () => setState(() => showQueued = false)),
                  TextButton(onPressed: () => setState(() => showQueued = false), child: const Text('Keep swiping', style: TextStyle(color: _blue, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JobDetail extends StatelessWidget {
  final JobItem job;
  const JobDetail({super.key, required this.job});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        leading: CircleBack(),
        title: Text('Full description', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              job.photo,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 200, color: _tint),
            ),
          ),
          const SizedBox(height: 14),
          Text(job.title, style: const TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('${job.company}  •  ${job.location}', style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 16),
          DjCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About the role', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  'Normalized posting body goes here. Quotes stay verbatim from the ATS. Expanding pauses the dwell timer so decision speed stays clean.',
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryPill(label: 'Apply with agent', icon: Icons.auto_awesome_outlined, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

// Applications. Luma list discipline.

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Applications', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHead(title: 'Review queue', sub: 'Every tailored artifact waits for your approval. No approve all.'),
          const SizedBox(height: 14),
          _app('Fathom Analytics', 'Senior Backend', 'AWAITING REVIEW', 'Resume plus 12 percent keywords. Cover letter ready.', _navy, _tint),
          _app('Northwind', 'Platform Engineer', 'NEEDS ATTENTION', 'Missing answer: salary expectation.', _amberInk, _amberBg),
          _app('Mercury', 'Staff Data', 'SUBMITTED', 'Sent and verified by confirmation email.', _green, _greenBg),
          _app('Acme Workday', 'Backend', 'FILLING FORM', 'Agent filling form. Gmail OTP automatic.', _blue, _tint),
        ],
      ),
    );
  }

  Widget _app(String co, String role, String status, String sub, Color fg, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DjCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('$co  •  $role', style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14))),
                StatusPill(label: status, fg: fg, bg: bg),
              ],
            ),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Diff: 3 bullets adjusted. Hash verified against attached PDF.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: PrimaryPill(label: 'Review', onTap: () {})),
                const SizedBox(width: 10),
                Expanded(child: SecondaryPill(label: 'Abandon', onTap: () {})),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Interviews. Mailbox detected list plus agent call sheet.

class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Interviews', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHead(title: 'Where you got interviews', sub: 'Detected from your inbox by mailbox sync.'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.mail_outline, color: _blue, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('3 interviews  •  2 awaiting feedback', style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700))),
                StatusPill(label: 'SYNC 2H', fg: _navy, bg: _tint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _row(context, 'Fathom Analytics', 'Senior Backend', 'Final on site  •  18 Sep', 'UPCOMING', _navy, _tint, 'Share how it went', true),
          _row(context, 'Northwind', 'Platform Engineer', 'Intro call done  •  12 Sep', 'DONE', _muted, _wash, 'Give feedback', false),
          _row(context, 'Mercury', 'Staff Data', 'Technical  •  10 Sep', 'DONE', _muted, _wash, 'Give feedback', false),
        ],
      ),
    );
  }

  Widget _row(BuildContext ctx, String co, String role, String when, String state, Color fg, Color bg, String cta, bool upcoming) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DjCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(co[0], style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(co, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(role, style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                StatusPill(label: state, fg: fg, bg: bg),
              ],
            ),
            const SizedBox(height: 8),
            Text(when, style: const TextStyle(color: _muted, fontSize: 11)),
            const SizedBox(height: 12),
            PrimaryPill(label: cta, icon: Icons.phone_outlined, onTap: () => _sheet(ctx, co, upcoming)),
          ],
        ),
      ),
    );
  }

  void _sheet(BuildContext ctx, String co, bool upcoming) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                const OwlBadge(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upcoming ? 'Prep call for $co' : 'Debrief call for $co', style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 15)),
                      const Text('The agent asks what happened and returns tips for next time.', style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryPill(label: 'Confirm call', icon: Icons.call_outlined, onTap: () => Navigator.pop(ctx)),
            const SizedBox(height: 8),
            SecondaryPill(label: 'Cancel', onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }
}

// Coach. Practice on demand plus call history.

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  bool ringing = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Coach', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHead(title: 'Interview coach', sub: 'The agent calls you, asks for detail, and sharpens the next one.'),
          const SizedBox(height: 14),
          DjCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    OwlBadge(size: 44),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practice now', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('Ask for a call whenever you want to train.', style: TextStyle(color: _muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PrimaryPill(label: 'Ask for a practice call', icon: Icons.call_outlined, onTap: () => setState(() => ringing = true)),
                if (ringing) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _navy)),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Calling. The agent reaches you in 30 seconds.', style: TextStyle(color: _ink, fontSize: 12))),
                        TextButton(onPressed: () => setState(() => ringing = false), child: const Text('Hang up', style: TextStyle(color: _blue))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('CALL HISTORY', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _call('Post interview feedback', 'Fathom  •  12 Sep  •  4 min', 'Use STAR. Quantify impact. Avoid internal jargon.', true),
          _call('Technical mock', 'Practice  •  10 Sep  •  6 min', 'Score 7 of 10. Improve system design tradeoffs.', false),
          _call('Mercury debrief', 'Mercury  •  09 Sep  •  3 min', 'Ask about on call before closing.', false),
        ],
      ),
    );
  }

  Widget _call(String title, String meta, String tip, bool latest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DjCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: latest ? _navy : _wash, shape: BoxShape.circle),
              child: Icon(Icons.record_voice_over_outlined, color: latest ? Colors.white : _muted, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(meta, style: const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(tip, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (latest) const StatusPill(label: 'NEW', fg: Colors.white, bg: _navy),
          ],
        ),
      ),
    );
  }
}

// Profile. Luma grouped rows.

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Profile', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          DjCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', width: 64, height: 64, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Santiago, 24  •  Bogota', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('santiago@gmail.com', style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: _muted, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _line)),
            child: Column(
              children: [
                _groupRow(Icons.mail_outline, 'Gmail for OTP', 'Agent reads codes automatically', true, true),
                const Divider(height: 1, color: _line, indent: 16, endIndent: 16),
                _groupRow(Icons.sms_outlined, 'SMS 2FA', 'Fallback when mail fails', false, true),
                const Divider(height: 1, color: _line, indent: 16, endIndent: 16),
                _groupRow(Icons.description_outlined, 'Master resume', 'ATS score 78 of 100', true, true),
                const Divider(height: 1, color: _line, indent: 16, endIndent: 16),
                _groupRow(Icons.work_outline, 'Preferences', 'Remote, Go, 70k floor', true, false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _line)),
            child: _groupRow(Icons.shield_outlined, 'Privacy', 'Revoke Gmail, delete data', false, false),
          ),
          const SizedBox(height: 16),
          SecondaryPill(label: 'Log out', onTap: () {}),
        ],
      ),
    );
  }

  Widget _groupRow(IconData icon, String title, String sub, bool on, bool divider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _wash, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _navy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sub, style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: on ? _navy : _line, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
