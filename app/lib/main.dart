import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth.dart';
import 'auth/data/supabase_auth_repository.dart';
import 'core/config_error_app.dart';
import 'router/app_router.dart';
import 'theme.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }
  // ignore: deprecated_member_use
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(DreamJobApp(
    auth: AuthProvider(repository: SupabaseAuthRepository(Supabase.instance.client)),
  ));
}

class DreamJobApp extends StatefulWidget {
  const DreamJobApp({super.key, this.auth});

  /// Proveedor de autenticación. Si es null se crea uno en memoria.
  final AuthProvider? auth;

  @override
  State<DreamJobApp> createState() => _DreamJobAppState();
}

class _DreamJobAppState extends State<DreamJobApp> {
  late final AuthProvider _auth = widget.auth ?? AuthProvider();
  late final GoRouter _router = buildRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: navy, brightness: Brightness.light),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ink,
      ),
    );
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'dreamJob',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: light,
        themeMode: ThemeMode.light,
        routerConfig: _router,
      ),
    );
  }
}
