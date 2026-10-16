import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/auth_error_mapper.dart';
import '../data/auth_repository.dart';
import '../data/candidate_profile.dart';
import '../data/in_memory_auth_repository.dart';
import '../data/recruiter_profile.dart';
import '../data/user_role.dart';

/// Estado de autenticación de la app. Sin repositorio usa uno en memoria
/// (pruebas y desarrollo sin Supabase).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repo = repository ?? InMemoryAuthRepository() {
    _signedOutSub = _repo.onSignedOut.listen((_) => _clearSession());
    _restore();
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _signedOutSub;
  bool _disposed = false;

  bool _loading = false;
  bool _initialized = false;
  String? _error;
  UserRole? _role;
  CandidateProfile? _candidate;
  RecruiterProfile? _recruiter;

  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;
  UserRole? get role => _role;
  CandidateProfile? get candidate => _candidate;
  RecruiterProfile? get recruiter => _recruiter;
  bool get isAuthenticated => _role != null;

  Future<bool> signIn(String email, String password) {
    return _run(() => _repo.signIn(email, password));
  }

  Future<bool> signUpCandidate({
    required String nombre,
    required String email,
    required String password,
    required String ciudad,
    required DateTime fechaNacimiento,
    String? resumenPerfil,
  }) {
    return _run(() => _repo.signUpCandidate(
          nombre: nombre,
          email: email,
          password: password,
          ciudad: ciudad,
          fechaNacimiento: fechaNacimiento,
          resumenPerfil: resumenPerfil,
        ));
  }

  Future<bool> signUpRecruiter({
    required String nombre,
    required String email,
    required String password,
    required String empresaNombre,
    required String empresaDescripcion,
    required String empresaMonograma,
  }) {
    return _run(() => _repo.signUpRecruiter(
          nombre: nombre,
          email: email,
          password: password,
          empresaNombre: empresaNombre,
          empresaDescripcion: empresaDescripcion,
          empresaMonograma: empresaMonograma,
        ));
  }

  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // El cierre local siempre debe completarse aunque falle la red.
    }
    _clearSession();
  }

  Future<void> _restore() async {
    try {
      final session = await _repo.restoreSession();
      if (session != null) _apply(session);
    } catch (_) {
      // Sin sesión recuperable: el router envía al login.
    }
    _initialized = true;
    _notify();
  }

  Future<bool> _run(Future<SessionData> Function() action) async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _apply(await action());
      _loading = false;
      _notify();
      return true;
    } catch (e) {
      _loading = false;
      _error = mapAuthError(e);
      _notify();
      return false;
    }
  }

  void _apply(SessionData session) {
    _role = session.role;
    _candidate = session.candidate;
    _recruiter = session.recruiter;
  }

  void _clearSession() {
    _role = null;
    _candidate = null;
    _recruiter = null;
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _signedOutSub.cancel();
    super.dispose();
  }
}
