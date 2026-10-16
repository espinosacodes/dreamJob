import 'candidate_profile.dart';
import 'recruiter_profile.dart';
import 'user_role.dart';

/// Sesión iniciada: rol y perfil cargado (uno de los dos según el rol).
class SessionData {
  const SessionData.candidate(CandidateProfile this.candidate)
      : role = UserRole.candidato,
        recruiter = null;

  const SessionData.recruiter(RecruiterProfile this.recruiter)
      : role = UserRole.reclutador,
        candidate = null;

  final UserRole role;
  final CandidateProfile? candidate;
  final RecruiterProfile? recruiter;
}

/// Acceso al backend de autenticación. Los errores se lanzan como
/// excepciones; AuthProvider los traduce a mensajes en español.
abstract class AuthRepository {
  /// Sesión guardada en el dispositivo con su perfil, o null si no hay.
  Future<SessionData?> restoreSession();

  /// Se emite cuando el backend cierra la sesión por su cuenta
  /// (token revocado o vencido).
  Stream<void> get onSignedOut;

  Future<SessionData> signIn(String email, String password);

  Future<SessionData> signUpCandidate({
    required String nombre,
    required String email,
    required String password,
    required String ciudad,
    required DateTime fechaNacimiento,
    String? resumenPerfil,
  });

  Future<SessionData> signUpRecruiter({
    required String nombre,
    required String email,
    required String password,
    required String empresaNombre,
    required String empresaDescripcion,
    required String empresaMonograma,
  });

  Future<void> signOut();
}
