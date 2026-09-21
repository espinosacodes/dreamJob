import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Profile. Luma grouped rows.

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        title: Text('Profile', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
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
                      Text('Santiago, 24  •  Bogota', style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('santiago@gmail.com', style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: muted, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: line)),
            child: Column(
              children: [
                _groupRow(Icons.mail_outline, 'Gmail for OTP', 'Agent reads codes automatically', true, true),
                const Divider(height: 1, color: line, indent: 16, endIndent: 16),
                _groupRow(Icons.sms_outlined, 'SMS 2FA', 'Fallback when mail fails', false, true),
                const Divider(height: 1, color: line, indent: 16, endIndent: 16),
                _groupRow(Icons.description_outlined, 'Master resume', 'ATS score 78 of 100', true, true),
                const Divider(height: 1, color: line, indent: 16, endIndent: 16),
                _groupRow(Icons.work_outline, 'Preferences', 'Remote, Go, 70k floor', true, false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: line)),
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
            decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: navy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sub, style: const TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: on ? navy : line, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
