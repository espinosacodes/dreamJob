import 'dart:async';

import '../../core/auth_failure.dart';
import 'auth_repository.dart';
import 'candidate_profile.dart';
import 'company.dart';
import 'recruiter_profile.dart';

/// Repositorio sin backend: guarda los usuarios en memoria. Se usa en pruebas
/// y mientras no hay claves de Supabase.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({
    this.latency = const Duration(milliseconds: 300),
    this.restoreDelay = const Duration(milliseconds: 1500),
  });

  final Duration latency;
  final Duration restoreDelay;

  final Map<String, _StubUser> _users = {};
  final StreamController<void> _signedOut = StreamController<void>.broadcast();
  int _seq = 0;

  @override
  Stream<void> get onSignedOut => _signedOut.stream;

  @override
  Future<SessionData?> restoreSession() async {
    await Future<void>.delayed(restoreDelay);
    return null;
  }

  @override
  Future<SessionData> signIn(String email, String password) async {
    await Future<void>.delayed(latency);
    final user = _users[_key(email)];
    if (user == null || user.password != password) {
      throw const AuthFailure('Correo o contraseña incorrectos');
    }
    return user.session;
  }

  @override
  Future<SessionData> signUpCandidate({
    required String nombre,
    required String email,
    required String password,
    required String ciudad,
    required DateTime fechaNacimiento,
    String? resumenPerfil,
  }) async {
    await Future<void>.delayed(latency);
    final key = _key(email);
    _ensureFree(key);
    final session = SessionData.candidate(CandidateProfile(
      id: 'stub-${++_seq}',
      nombre: nombre.trim(),
      email: email.trim(),
      ciudad: ciudad.trim(),
      fechaNacimiento: fechaNacimiento,
      resumenPerfil: resumenPerfil?.trim(),
    ));
    _users[key] = _StubUser(password, session);
    return session;
  }

  @override
  Future<SessionData> signUpRecruiter({
    required String nombre,
    required String email,
    required String password,
    required String empresaNombre,
    required String empresaDescripcion,
    required String empresaMonograma,
  }) async {
    await Future<void>.delayed(latency);
    final key = _key(email);
    _ensureFree(key);
    final session = SessionData.recruiter(RecruiterProfile(
      id: 'stub-${++_seq}',
      nombre: nombre.trim(),
      email: email.trim(),
      empresa: Company(
        id: 'stub-co-$_seq',
        nombre: empresaNombre.trim(),
        descripcion: empresaDescripcion.trim(),
        monograma: empresaMonograma.trim(),
      ),
    ));
    _users[key] = _StubUser(password, session);
    return session;
  }

  @override
  Future<void> signOut() async {}

  String _key(String email) => email.trim().toLowerCase();

  void _ensureFree(String key) {
    if (_users.containsKey(key)) {
      throw const AuthFailure('Este correo ya está registrado');
    }
  }
}

class _StubUser {
  _StubUser(this.password, this.session);

  final String password;
  final SessionData session;
}
