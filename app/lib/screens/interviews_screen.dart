import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Interviews. Mailbox detected list plus agent call sheet.

class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Interviews', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHead(title: 'Where you got interviews', sub: 'Detected from your inbox by mailbox sync.'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.mail_outline, color: blue, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('3 interviews  •  2 awaiting feedback', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700))),
                StatusPill(label: 'SYNC 2H', fg: navy, bg: tint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _row(context, 'Rappi', 'Senior Backend', 'Final on site  •  18 Sep', 'UPCOMING', navy, tint, 'Share how it went', true),
          _row(context, 'Google', 'Frontend Engineer', 'Intro call done  •  12 Sep', 'DONE', muted, wash, 'Give feedback', false),
          _row(context, 'Nubank', 'Platform Engineer', 'Technical  •  10 Sep', 'DONE', muted, wash, 'Give feedback', false),
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
                CompanyMark(company: co, mono: co.isEmpty ? '?' : co[0], size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(co, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(role, style: const TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
                StatusPill(label: state, fg: fg, bg: bg),
              ],
            ),
            const SizedBox(height: 8),
            Text(when, style: const TextStyle(color: muted, fontSize: 11)),
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                const OwlBadge(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upcoming ? 'Prep call for $co' : 'Debrief call for $co', style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 15)),
                      const Text('The agent asks what happened and returns tips for next time.', style: TextStyle(color: muted, fontSize: 12)),
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
