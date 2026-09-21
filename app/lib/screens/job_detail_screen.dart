import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class JobDetail extends StatelessWidget {
  final JobItem job;
  const JobDetail({super.key, required this.job});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const FrostedTop(
        leading: CircleBack(),
        title: Text('Full description', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
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
              errorBuilder: (_, __, ___) => Container(height: 200, color: tint),
            ),
          ),
          const SizedBox(height: 14),
          Text(job.title, style: const TextStyle(color: ink, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('${job.company}  •  ${job.location}', style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 16),
          DjCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About the role', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  'Normalized posting body goes here. Quotes stay verbatim from the ATS. Expanding pauses the dwell timer so decision speed stays clean.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
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
