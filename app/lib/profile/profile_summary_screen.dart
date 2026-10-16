import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth.dart';

class ProfileSummaryScreen extends StatelessWidget {
  const ProfileSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ProfileSummaryScreen'),
            TextButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
