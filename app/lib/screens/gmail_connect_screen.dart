import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

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
        title: Text('Agent setup', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
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
                    Icon(Icons.auto_awesome_outlined, color: blue, size: 18),
                    SizedBox(width: 8),
                    Text('Auto apply agent', style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'When a company asks for a code, the agent extracts it from Gmail and completes the form. You keep swiping.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, color: blue, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Gmail connected', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: gmail,
                        activeColor: blue,
                        onChanged: (v) => setState(() => gmail = v),
                      ),
                    ],
                  ),
                ),
                if (!gmail)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: amberBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: amberLine)),
                    child: const Text(
                      'Without Gmail the agent pauses on every OTP and asks you manually.',
                      style: TextStyle(color: amberInk, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('2FA CHANNEL', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: line)),
            child: Column(
              children: [
                _radioRow('By mail', 'Fastest. Agent reads it in seconds.', Icons.mail_outline, channel == 'mail', () => setState(() => channel = 'mail'), true),
                const Divider(height: 1, color: line, indent: 16, endIndent: 16),
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
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.bolt_outlined, color: navy, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Mail is recommended. Zero taps during a swipe session.', style: TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
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
            child: Text('OAuth Google  •  gmail.readonly  •  revocable', style: TextStyle(color: muted, fontSize: 11)),
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
              decoration: BoxDecoration(color: selected ? tint : wash, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: selected ? navy : muted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(sub, style: const TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? navy : Colors.transparent,
                border: Border.all(color: selected ? navy : line, width: 2),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }
}
