import 'package:go_router/go_router.dart';

import '../auth/auth.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/register_candidate_screen.dart';
import '../auth/screens/register_recruiter_screen.dart';
import '../auth/screens/register_role_screen.dart';
import '../profile/profile_summary_screen.dart';
import '../screens/splash_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!auth.initialized) return loc == '/splash' ? null : '/splash';

      final isPublic = loc == '/login' || loc.startsWith('/register');
      if (auth.isAuthenticated) {
        return (loc == '/splash' || isPublic) ? '/profile' : null;
      }
      return isPublic ? null : '/login';
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterRoleScreen(),
        routes: [
          GoRoute(
            path: 'candidato',
            builder: (_, _) => const RegisterCandidateScreen(),
          ),
          GoRoute(
            path: 'reclutador',
            builder: (_, _) => const RegisterRecruiterScreen(),
          ),
        ],
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileSummaryScreen()),
    ],
  );
}
