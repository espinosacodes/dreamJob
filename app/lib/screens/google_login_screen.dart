import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'gmail_connect_screen.dart';

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
                decoration: BoxDecoration(color: wash, shape: BoxShape.circle, border: Border.all(color: line)),
                child: const Icon(Icons.mail_outline, color: blue, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to dreamJob',
                textAlign: TextAlign.center,
                style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect Gmail once. The agent reads the OTP code for you and finishes each application.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 14, height: 1.5),
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
                          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                            child: Text('G', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gmail for OTP', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('Read only. Codes only. Nothing else.', style: TextStyle(color: muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        const StatusPill(label: 'AUTO', fg: navy, bg: tint),
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
                      style: TextStyle(color: muted, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OAuth with gmail.readonly scope. No password stored. Revoke anytime in Profile.',
                        style: TextStyle(color: muted, fontSize: 11, height: 1.4),
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
                  child: const Text('Set up agent', style: TextStyle(color: blue, fontWeight: FontWeight.w700)),
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
