import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('RegisterRoleScreen'),
            TextButton(
              onPressed: () => context.go('/register/candidato'),
              child: const Text('Soy candidato'),
            ),
            TextButton(
              onPressed: () => context.go('/register/reclutador'),
              child: const Text('Soy reclutador'),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
