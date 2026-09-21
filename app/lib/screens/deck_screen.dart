import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'job_detail_screen.dart';

// Deck. Job cards on white, Bumble card discipline.

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
          backgroundColor: ink,
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
          style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: StatusPill(label: 'STRONG', fg: navy, bg: tint)),
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
                                              color: i == 0 ? navy : line,
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
                                              color: tint,
                                              child: const Center(child: Icon(Icons.business_outlined, color: navy, size: 32)),
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
                                        CompanyMark(company: j.company, mono: j.mono),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(j.company, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.verified, color: blue, size: 15),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(j.posted, style: const TextStyle(color: muted, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      j.title,
                                      style: const TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.1),
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
                                            color: hot ? tint : wash,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: hot ? skySoft : line),
                                          ),
                                          child: Text(
                                            s,
                                            style: TextStyle(color: hot ? navy : muted, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        children: j.bullets
                                            .map(
                                              (b) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: const BoxDecoration(color: navy, shape: BoxShape.circle)),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(b, style: const TextStyle(color: ink, fontSize: 13, height: 1.4))),
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
                                      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('WHY THIS CARD', style: TextStyle(color: navy, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                                          const SizedBox(height: 4),
                                          Text(j.reasons.join('  •  '), style: const TextStyle(color: navy, fontSize: 12, height: 1.4)),
                                        ],
                                      ),
                                    ),
                                    if (j.warning != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: amberBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: amberLine)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, color: amberInk, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text(j.warning!, style: const TextStyle(color: amberInk, fontSize: 11, height: 1.4))),
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
                                    const Center(child: Text('Tap card for full description', style: TextStyle(color: muted, fontSize: 10))),
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
                                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: navy, width: 2.5), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('APPLY', style: TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 18)),
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
                                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: muted, width: 2.5), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('SKIP', style: TextStyle(color: muted, fontWeight: FontWeight.w900, fontSize: 18)),
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
                    _circleBtn(Icons.undo, muted, () => setState(() => top = (top - 1) % jobs.length)),
                    _circleBtn(Icons.close, navy, () => _swipe(false), big: true),
                    _circleBtn(Icons.star_outline, sky, () => _swipe(true)),
                    _circleBtn(Icons.favorite, sky, () => _swipe(true), big: true),
                    _circleBtn(Icons.bookmark_border, muted, () {}),
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
        Icon(icon, color: muted, size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: muted, fontSize: 12))),
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
          border: Border.all(color: line),
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
                  const Text('Queued for tailoring', textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'The agent is tailoring your resume and cover letter. Review before anything is sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 4, child: LinearProgressIndicator(color: navy, backgroundColor: line)),
                  const SizedBox(height: 16),
                  PrimaryPill(label: 'View in Apps', onTap: () => setState(() => showQueued = false)),
                  TextButton(onPressed: () => setState(() => showQueued = false), child: const Text('Keep swiping', style: TextStyle(color: blue, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
