import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Applications. Luma list discipline.

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Applications', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHead(title: 'Review queue', sub: 'Every tailored artifact waits for your approval. No approve all.'),
          const SizedBox(height: 14),
          _app('Rappi', 'Senior Backend', 'AWAITING REVIEW', 'Resume plus 12 percent keywords. Cover letter ready.', navy, tint),
          _app('Google', 'Frontend Engineer', 'NEEDS ATTENTION', 'Missing answer: salary expectation.', amberInk, amberBg),
          _app('Nubank', 'Platform Engineer', 'SUBMITTED', 'Sent and verified by confirmation email.', green, greenBg),
          _app('Platzi', 'Staff Data', 'FILLING FORM', 'Agent filling form. Gmail OTP automatic.', blue, tint),
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
                CompanyMark(company: co, mono: co.isEmpty ? '?' : co[0], size: 32),
                const SizedBox(width: 8),
                Expanded(child: Text('$co  •  $role', style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 14))),
                StatusPill(label: status, fg: fg, bg: bg),
              ],
            ),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Diff: 3 bullets adjusted. Hash verified against attached PDF.',
                style: TextStyle(color: muted, fontSize: 11),
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
