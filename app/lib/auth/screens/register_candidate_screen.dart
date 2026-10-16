import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterCandidateScreen extends StatelessWidget {
  const RegisterCandidateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('RegisterCandidateScreen'),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
