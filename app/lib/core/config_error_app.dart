import 'package:flutter/material.dart';

/// Pantalla mínima cuando faltan SUPABASE_URL o SUPABASE_ANON_KEY.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  'Falta configurar Supabase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Crea el archivo app/.env con SUPABASE_URL y SUPABASE_ANON_KEY '
                  'y ejecuta la app con --dart-define-from-file=.env',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
