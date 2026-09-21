import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
        title: Text('Coach', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
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
                          Text('Practice now', style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('Ask for a call whenever you want to train.', style: TextStyle(color: muted, fontSize: 12)),
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
                    decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: navy)),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Calling. The agent reaches you in 30 seconds.', style: TextStyle(color: ink, fontSize: 12))),
                        TextButton(onPressed: () => setState(() => ringing = false), child: const Text('Hang up', style: TextStyle(color: blue))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('CALL HISTORY', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
              decoration: BoxDecoration(color: latest ? navy : wash, shape: BoxShape.circle),
              child: Icon(Icons.record_voice_over_outlined, color: latest ? Colors.white : muted, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(meta, style: const TextStyle(color: muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(tip, style: const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (latest) const StatusPill(label: 'NEW', fg: Colors.white, bg: navy),
          ],
        ),
      ),
    );
  }
}
