import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterRecruiterScreen extends StatelessWidget {
  const RegisterRecruiterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('RegisterRecruiterScreen'),
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
