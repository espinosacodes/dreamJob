import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const DreamJobApp());

// palette from user
const _p0 = Color(0xFF012a4a);
const _p1 = Color(0xFF013a63);
const _p2 = Color(0xFF01497c);
const _p3 = Color(0xFF014f86);
const _p4 = Color(0xFF2a6f97);
const _p5 = Color(0xFF2c7da0);
const _p6 = Color(0xFF468faf);
const _p7 = Color(0xFF61a5c2);
const _p8 = Color(0xFF89c2d9);
const _p9 = Color(0xFFa9d6e5);

class DreamJobApp extends StatelessWidget {
  const DreamJobApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DreamJob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _p0,
        colorScheme: ColorScheme.fromSeed(seedColor: _p4, brightness: Brightness.dark),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------- shared glass ----------
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  const GlassCard({super.key, required this.child, this.radius = 20, this.padding, this.blur = 18, this.opacity = 0.14});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.06)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class OwlIcon extends StatelessWidget {
  final double size;
  const OwlIcon({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_p1, _p3, _p0]),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // subtle owl body silhouette
            Icon(Icons.pets, size: size * 0.55, color: _p5.withOpacity(0.35)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _eye(size * 0.32),
                SizedBox(width: size * 0.04),
                _eye(size * 0.32),
              ],
            ),
            // glasses bridge
            Positioned(
              top: size * 0.36,
              child: Container(width: size * 0.08, height: 3, color: _p0),
            ),
            // beak
            Positioned(
              top: size * 0.52,
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: BoxDecoration(color: _p8.withOpacity(0.9), borderRadius: BorderRadius.circular(2)),
                child: const Icon(Icons.arrow_drop_down, size: 14, color: _p0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eye(double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _p0, width: 3),
        ),
        child: Center(
          child: Container(
            width: s * 0.45,
            height: s * 0.45,
            decoration: const BoxDecoration(color: _p0, shape: BoxShape.circle),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(width: s * 0.12, height: s * 0.12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ),
          ),
        ),
      );
}

// ---------- SPLASH ----------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GoogleLoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_p0, _p1, _p2, _p4]),
        ),
        child: Stack(
          children: [
            // liquid orbs
            Positioned(top: -60, right: -40, child: _orb(220, _p6.withOpacity(0.35))),
            Positioned(bottom: -30, left: -50, child: _orb(260, _p5.withOpacity(0.28))),
            Positioned(top: 180, left: 40, child: _orb(120, _p8.withOpacity(0.18))),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OwlIcon(size: 96),
                  const SizedBox(height: 18),
                  const Text('dreamJob', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                  const SizedBox(height: 6),
                  Text('swipe. match. hired.', style: TextStyle(color: _p9.withOpacity(0.9), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 28),
                  GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    opacity: 0.10,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: _p8, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('agente que aplica por ti', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(child: Text('Prototype  •  pixel ready', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [BoxShadow(color: c, blurRadius: 40)]),
      );
}

// ---------- GOOGLE LOGIN + GMAIL OTP ----------
class GoogleLoginScreen extends StatelessWidget {
  const GoogleLoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_p0, _p1, _p2])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const OwlIcon(size: 64),
                const SizedBox(height: 12),
                const Text('Bienvenido a dreamJob', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Tu agente aplica mientras tu haces swipe', textAlign: TextAlign.center, style: TextStyle(color: _p9.withOpacity(0.85), fontSize: 13)),
                const SizedBox(height: 28),
                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.mail, color: _p2, size: 20)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Conexion Gmail para OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)), Text('El agente lee el codigo de verificacion automaticamente', style: TextStyle(color: Colors.white70, fontSize: 11))])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _p8.withOpacity(0.9), borderRadius: BorderRadius.circular(12)), child: const Text('auto', style: TextStyle(color: _p0, fontSize: 10, fontWeight: FontWeight.w800))),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GmailConnectScreen())),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Text('G', style: TextStyle(color: _p2, fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                          label: const Text('Continuar con Google', style: TextStyle(color: _p0, fontWeight: FontWeight.w700, fontSize: 15)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), elevation: 0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Solo Google. No Apple, no Line. OTP llega a tu Gmail y el agente lo resuelve.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                    ],
                  ),
                ),
                const Spacer(),
                GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  opacity: 0.08,
                  child: Row(children: [
                    const Icon(Icons.shield_outlined, color: _p9, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Nunca pedimos tu password. OAuth Gmail scope gmail.readonly para codigos. 2FA por mail o SMS tu eliges.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11))),
                  ]),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: () {}, child: Text('Trouble signing in?', style: TextStyle(color: _p9.withOpacity(0.8), fontSize: 12))),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GmailConnectScreen extends StatefulWidget {
  const GmailConnectScreen({super.key});
  @override
  State<GmailConnectScreen> createState() => _GmailConnectScreenState();
}

class _GmailConnectScreenState extends State<GmailConnectScreen> {
  bool gmail = true;
  String twoFA = 'mail'; // mail | sms
  final phoneCtrl = TextEditingController(text: '+57 300 000 0000');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p0,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)), title: const Text('Configura tu agente', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_p0, _p1])),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.auto_awesome, color: _p8, size: 18), const SizedBox(width: 8), const Text('Agente auto-aplica', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Text('Cuando una empresa pide codigo de verificacion, el agente lo extrae de tu Gmail por regex y completa la aplicacion. Tu no copias nada.', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.mail_outline, color: _p9, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Gmail conectado', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                  Switch(value: gmail, activeColor: _p7, onChanged: (v) => setState(() => gmail = v)),
                ]),
                if (!gmail) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Text('Sin Gmail el agente no puede auto completar OTP. Se pedira manual.', style: TextStyle(color: Colors.orange, fontSize: 11))),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('2FA preferido', style: TextStyle(color: _p9, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _choice('Por mail', Icons.mail, twoFA == 'mail', () => setState(() => twoFA = 'mail'))),
              const SizedBox(width: 12),
              Expanded(child: _choice('Por SMS', Icons.sms, twoFA == 'sms', () => setState(() => twoFA = 'sms'))),
            ]),
            const SizedBox(height: 12),
            GlassCard(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(twoFA == 'mail' ? 'Codigo llega a tu Gmail' : 'Codigo llega a tu telefono', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Text(twoFA == 'mail' ? 'Recomendado. El agente lo lee en segundos sin interrumpir tu swipe.' : 'El agente te mostrara el prompt SMS y tu lo pegas. Latencia ~ 1 min.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                if (twoFA == 'sms') ...[
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: Colors.white.withOpacity(0.08), hintText: 'Telefono', hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false),
                child: const Text('Conectar y entrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text('OAuth Google  •  gmail.readonly  •  puedes revocar en Perfil', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _choice(String label, IconData icon, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: GlassCard(
          radius: 16,
          opacity: sel ? 0.18 : 0.08,
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Icon(icon, color: sel ? _p8 : Colors.white70, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? _p8 : Colors.transparent, border: Border.all(color: Colors.white30))),
          ]),
        ),
      );
}

// ---------- HOME SHELL ----------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;
  final pages = const [DeckScreen(), ApplicationsScreen(), InterviewsScreen(), CoachScreen(), ProfileScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_p0, _p1, _p2])),
        child: pages[idx],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.14))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _nav(0, Icons.style, 'Deck'),
                  _nav(1, Icons.article_outlined, 'Apps', badge: '4'),
                  _nav(2, Icons.event_available, 'Entrevistas', badge: '3'),
                  _nav(3, Icons.phone_in_talk, 'Coach', dot: true),
                  _nav(4, Icons.person_outline, 'Perfil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label, {String? badge, bool dot = false}) {
    final sel = i == idx;
    return GestureDetector(
      onTap: () => setState(() => idx = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: sel ? Colors.white.withOpacity(0.16) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, color: sel ? Colors.white : Colors.white70, size: 20),
            if (badge != null)
              Positioned(right: -10, top: -6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: _p8, borderRadius: BorderRadius.circular(10)), child: Text(badge, style: const TextStyle(color: _p0, fontSize: 10, fontWeight: FontWeight.w800)))),
            if (dot) Positioned(right: -4, top: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _p7, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
          ]),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ---------- DECK JOBS ----------
class JobCardData {
  final String title, company, location, workMode, comp, compProv, posted;
  final List<String> stack;
  final List<String> bullets;
  final List<String> reasons;
  final String? warning;
  JobCardData({required this.title, required this.company, required this.location, required this.workMode, required this.comp, required this.compProv, required this.posted, required this.stack, required this.bullets, required this.reasons, this.warning});
}

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});
  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  int top = 0;
  double drag = 0;
  bool showApply = false;
  final jobs = [
    JobCardData(title: 'Senior Backend Engineer', company: 'Fathom Analytics', location: 'Remote  •  EU timezone UTC+0 to +3', workMode: 'Remote', comp: '€95k – €120k', compProv: 'posted', posted: 'hace 3 dias', stack: ['Go', 'Kubernetes', 'Postgres', 'gRPC', 'Redis', '+2'], bullets: ['Own the payments ingestion pipeline', '5-person platform team, no on-call', 'Series B, 60 people'], reasons: ['Go + Kubernetes en tu stack', 'Remote en tu banda', 'Sobre tu comp floor'], warning: 'Title dice Remote, body dice 3 dias en oficina'),
    JobCardData(title: 'Platform Engineer', company: 'Northwind', location: 'Bogota  •  Hybrid 2d', workMode: 'Hybrid', comp: '\$80k – \$110k', compProv: 'estimado', posted: 'hace 1 dia', stack: ['Go', 'AWS', 'Terraform', 'Docker'], bullets: ['Build internal developer platform', '200 engineers as users', 'No visa needed'], reasons: ['Match fuerte en Go', 'Hybrid tolerable', 'Comp en rango'], warning: null),
    JobCardData(title: 'Staff Engineer, Data', company: 'Mercury', location: 'Remote  •  LATAM', workMode: 'Remote', comp: 'no range posted', compProv: '', posted: 'hace 5 dias', stack: ['Python', 'Postgres', 'Kafka'], bullets: ['Lead data ingestion', 'Greenfield, 0 a 1', 'Reporta a CTO'], reasons: ['Python en want list', 'Remote LATAM', 'Staff level'], warning: null),
  ];

  void _swipe(bool right) {
    if (right) {
      setState(() => showApply = true);
      Future.delayed(const Duration(milliseconds: 1400), () => setState(() => showApply = false));
    }
    setState(() { top = (top + 1) % jobs.length; drag = 0; });
  }

  @override
  Widget build(BuildContext context) {
    final j = jobs[top];
    return SafeArea(
      child: Stack(
        children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(children: [
                const OwlIcon(size: 32),
                const SizedBox(width: 10),
                GlassCard(radius: 14, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), opacity: 0.10, child: Row(children: [Icon(Icons.tune, color: Colors.white.withOpacity(0.9), size: 16), const SizedBox(width: 6), Text('${top + 1} / ${jobs.length}  •  deck diario', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600))])),
                const Spacer(),
                GlassCard(radius: 12, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), opacity: 0.12, child: Row(children: [const Icon(Icons.bolt, color: _p8, size: 16), const SizedBox(width: 4), Text('STRONG', style: TextStyle(color: _p9.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w800))])),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(() => drag += d.delta.dx),
                  onHorizontalDragEnd: (_) { if (drag > 90) _swipe(true); else if (drag < -90) _swipe(false); setState(() => drag = 0); },
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetail(job: j))),
                  child: Transform.rotate(
                    angle: drag * 0.0007,
                    child: Transform.translate(
                      offset: Offset(drag * 0.35, 0),
                      child: GlassCard(
                        radius: 24,
                        padding: const EdgeInsets.all(0),
                        opacity: 0.14,
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.04)])),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(j.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1))), Container(width: 8, height: 8, decoration: const BoxDecoration(color: _p8, shape: BoxShape.circle))]),
                              const SizedBox(height: 4),
                              Text(j.company, style: TextStyle(color: _p9.withOpacity(0.95), fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              _kv(Icons.public, j.location),
                              const SizedBox(height: 6),
                              _kv(Icons.payments_outlined, '${j.comp}  •  ${j.compProv}  •  ${j.posted}'),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, runSpacing: 6, children: j.stack.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: s.contains('Go') || s.contains('Kubernetes') ? _p7.withOpacity(0.9) : Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.14))), child: Text(s, style: TextStyle(color: s.contains('Go') ? Colors.white : Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600)))).toList()),
                              const SizedBox(height: 12),
                              Container(height: 1, color: Colors.white.withOpacity(0.10)),
                              const SizedBox(height: 12),
                              ...j.bullets.map((b) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: const BoxDecoration(color: _p8, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(b, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.3)))]))),
                              const SizedBox(height: 10),
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _p0.withOpacity(0.35), borderRadius: BorderRadius.circular(14), border: Border.all(color: _p8.withOpacity(0.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Por que ves esto', style: TextStyle(color: _p9.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(j.reasons.join('  •  '), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11))])),
                              if (j.warning != null) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16), const SizedBox(width: 6), Expanded(child: Text(j.warning!, style: const TextStyle(color: Colors.orange, fontSize: 11)))]))],
                              const Spacer(),
                              Row(children: [Expanded(child: OutlinedButton(onPressed: () => _swipe(false), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.18)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: const Text('←  Skip', style: TextStyle(color: Colors.white)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () => _swipe(true), style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: const Text('Apply  →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))]),
                              const SizedBox(height: 4),
                              Center(child: Text('⌄  full description', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _round(Icons.undo, Colors.white70, 20, () => setState(() => top = (top - 1) % jobs.length)),
                _round(Icons.close, _p8, 26, () => _swipe(false), big: true),
                _round(Icons.star, _p7, 22, () => _swipe(true)),
                _round(Icons.favorite, _p6, 26, () => _swipe(true), big: true),
                _round(Icons.bookmark_border, Colors.white70, 20, () {}),
              ]),
            ),
            const SizedBox(height: 90),
          ]),
          if (drag > 40) Positioned(top: 90, left: 24, child: Transform.rotate(angle: -0.18, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border.all(color: _p8, width: 3), borderRadius: BorderRadius.circular(8)), child: const Text('APPLY', style: TextStyle(color: _p8, fontWeight: FontWeight.w900, fontSize: 22))))),
          if (drag < -40) Positioned(top: 90, right: 24, child: Transform.rotate(angle: 0.18, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 3), borderRadius: BorderRadius.circular(8)), child: const Text('SKIP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 22))))),
          if (showApply) _applyOverlay(),
        ],
      ),
    );
  }

  Widget _kv(IconData i, String t) => Row(children: [Icon(i, color: _p9.withOpacity(0.85), size: 14), const SizedBox(width: 6), Expanded(child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)))]);

  Widget _round(IconData i, Color c, double s, VoidCallback onTap, {bool big = false}) => GestureDetector(onTap: onTap, child: GlassCard(radius: 99, padding: EdgeInsets.all(big ? 16 : 12), opacity: 0.12, child: Icon(i, color: c, size: s)));

  Widget _applyOverlay() => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(color: _p0.withOpacity(0.88), borderRadius: BorderRadius.circular(24)),
          child: Center(
            child: GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(24),
              opacity: 0.16,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome, color: _p8, size: 32),
                const SizedBox(height: 10),
                const Text('Aplicacion en cola', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Agente personalizando resume + cover letter', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                const SizedBox(height: 14),
                SizedBox(height: 3, width: 160, child: LinearProgressIndicator(color: _p8, backgroundColor: Colors.white.withOpacity(0.12))),
                const SizedBox(height: 10),
                Text('Undo disponible 10s', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ]),
            ),
          ),
        ),
      );
}

class JobDetail extends StatelessWidget {
  final JobCardData job;
  const JobDetail({super.key, required this.job});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p0,
      appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)), title: Text(job.company, style: const TextStyle(color: Colors.white))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(job.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('${job.workMode}  •  ${job.location}  •  ${job.comp}', style: TextStyle(color: _p9.withOpacity(0.9), fontSize: 12)),
        const SizedBox(height: 16),
        GlassCard(radius: 16, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Descripcion completa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('Full description del posting. Swipe up en deck pausa el dwell timer. Aqui iria el body real normalizado del ATS.', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.4))])),
        const SizedBox(height: 16),
        SizedBox(height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))), onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aplicacion encolada, revisa en Apps'))); }, child: const Text('Apply con agente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
      ]),
    );
  }
}

// ---------- APPLICATIONS (review queue) ----------
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Text('Aplicaciones', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)), const Spacer(), GlassCard(radius: 12, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), opacity: 0.12, child: Text('4 en revision', style: TextStyle(color: _p9.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _appCard('Fathom Analytics', 'Senior Backend', 'awaiting_review', 'Resume tailored +12% keywords', _p8, context),
                _appCard('Northwind', 'Platform Engineer', 'needs_attention', 'Falta respuesta: salary expectation', Colors.orange, context),
                _appCard('Mercury', 'Staff Data', 'submitted', 'Enviada  •  verificada email', _p7, context),
                _appCard('Acme Workday', 'Backend', 'filling_form', 'Agente llenando form  •  Gmail OTP auto', _p6, context),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _appCard(String co, String role, String status, String sub, Color c, BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text('$co  •  $role', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 6),
            Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(height: 56, color: Colors.white.withOpacity(0.06), child: Row(children: [Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text('Resume diff: 3 bullets ajustados, cover letter lista. Hash verificado.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10))))]))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () {}, child: const Text('Revisar', style: TextStyle(color: Colors.white, fontSize: 12)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.14)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () {}, child: Text('Abandonar', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)))),
            ]),
          ]),
        ),
      );
}

// ---------- INTERVIEWS ----------
class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Entrevistas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Detectadas desde tu inbox via mailbox sync', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          const SizedBox(height: 12),
          GlassCard(radius: 14, padding: const EdgeInsets.all(12), opacity: 0.10, child: Row(children: [const Icon(Icons.mail_outline, color: _p8, size: 18), const SizedBox(width: 8), Expanded(child: Text('3 entrevistas  •  2 pendientes de feedback', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _p8.withOpacity(0.9), borderRadius: BorderRadius.circular(12)), child: const Text('sync 2h', style: TextStyle(color: _p0, fontSize: 10, fontWeight: FontWeight.w700)))])),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _interview('Fathom Analytics', 'Senior Backend', 'On-site final  •  18 Sep', 'upcoming', 'Contar como te fue', context, true),
                _interview('Northwind', 'Platform Engineer', 'Intro call done  •  12 Sep', 'done', 'Dar feedback', context, false),
                _interview('Mercury', 'Staff Data', 'Tech interview  •  10 Sep', 'done', 'Dar feedback', context, false),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _interview(String co, String role, String when, String state, String cta, BuildContext ctx, bool upcoming) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: _p4.withOpacity(0.6), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(co[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(co, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)), Text(role, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11))])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: upcoming ? _p7.withOpacity(0.9) : Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(12)), child: Text(state, style: TextStyle(color: upcoming ? Colors.white : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 8),
            Text(when, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () => _callSheet(ctx, co),
                icon: const Icon(Icons.phone, color: Colors.white, size: 16),
                label: Text(cta, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );

  void _callSheet(BuildContext ctx, String co) => showModalBottomSheet(
        context: ctx,
        backgroundColor: _p1,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [const OwlIcon(size: 40), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Agente te llamara sobre $co', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), Text('Te preguntara como te fue, que te preguntaron y te dara tips', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11))]))]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Agente te llamara en 2 min sobre $co'))); }, child: const Text('Confirmar llamada', style: TextStyle(color: Colors.white)))),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 48, child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.14)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.8))))),
          ]),
        ),
      );
}

// ---------- COACH CALLS ----------
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  bool ringing = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Coach de entrevistas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('El agente te llama, pregunta y mejora tus siguientes entrevistas', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          const SizedBox(height: 14),
          GlassCard(
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _p8.withOpacity(0.9), shape: BoxShape.circle), child: const Icon(Icons.phone_in_talk, color: _p0, size: 20)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Practicar ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), Text('Pide que te llame cuando quieras entrenar', style: TextStyle(color: Colors.white70, fontSize: 11))]))]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _p4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  onPressed: () => setState(() => ringing = true),
                  icon: const Icon(Icons.call, color: Colors.white, size: 18),
                  label: const Text('Pedir que me llame para practicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              if (ringing) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _p0.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: _p8.withOpacity(0.3))), child: Row(children: [const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, color: _p8)), const SizedBox(width: 10), const Expanded(child: Text('Llamando... el agente te contacta en 30s', style: TextStyle(color: Colors.white, fontSize: 12))), TextButton(onPressed: () => setState(() => ringing = false), child: const Text('Colgar', style: TextStyle(color: Colors.orange)))])),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          Text('Historial de llamadas', style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _callTile('Feedback post-entrevista', 'Fathom  •  12 Sep  •  4 min', 'Tips: estructura STAR, cuantifica impacto, evita jerga interna', true),
                _callTile('Simulacro tecnico', 'Practica  •  10 Sep  •  6 min', 'Score 7/10  •  Mejorar: system design tradeoffs', false),
                _callTile('Debrief Mercury', 'Mercury  •  09 Sep  •  3 min', 'Tip: pregunta sobre on-call antes de cerrar', false),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _callTile(String title, String meta, String tip, bool latest) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          radius: 16,
          padding: const EdgeInsets.all(14),
          opacity: latest ? 0.16 : 0.10,
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _p5.withOpacity(0.6), shape: BoxShape.circle), child: const Icon(Icons.record_voice_over, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)), Text(meta, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)), const SizedBox(height: 4), Text(tip, style: TextStyle(color: _p8.withOpacity(0.9), fontSize: 11))])),
            if (latest) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: _p8.withOpacity(0.9), borderRadius: BorderRadius.circular(8)), child: const Text('nuevo', style: TextStyle(color: _p0, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
        ),
      );
}

// ---------- PROFILE ----------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', width: 72, height: 72, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Santiago, 24  •  Bogota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.18), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.check_circle, color: Colors.greenAccent, size: 12), SizedBox(width: 4), Text('Gmail conectado', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w700))])), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(12)), child: const Text('2FA mail', style: TextStyle(color: Colors.white70, fontSize: 11)))]), Text('santiago@gmail.com  •  +57 300 *** 1234', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11))])),
              const Icon(Icons.edit, color: Colors.white54, size: 18),
            ]),
          ),
          const SizedBox(height: 14),
          _profileRow(Icons.mail_outline, 'Gmail para OTP', 'agente lee codigos automaticamente', true),
          _profileRow(Icons.sms_outlined, 'SMS 2FA', 'fallback si mail falla', false),
          _profileRow(Icons.description_outlined, 'Master resume', 'ATS score 78/100', true),
          _profileRow(Icons.work_outline, 'Preferencias', 'Remote, Go, €70k floor', true),
          _profileRow(Icons.shield_outlined, 'Privacidad', 'Revocar Gmail, borrar datos', false),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 48, child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.14)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), onPressed: () {}, child: Text('Cerrar sesion', style: TextStyle(color: Colors.white.withOpacity(0.8))))),
          const SizedBox(height: 90),
        ]),
      ),
    );
  }

  Widget _profileRow(IconData i, String t, String s, bool on) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          radius: 16,
          padding: const EdgeInsets.all(14),
          opacity: 0.10,
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), Text(s, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11))])),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: on ? _p8 : Colors.white24, shape: BoxShape.circle)),
          ]),
        ),
      );
}
