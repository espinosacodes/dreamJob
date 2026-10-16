import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/candidate_profile.dart';
import '../data/company.dart';
import '../data/recruiter_profile.dart';
import '../data/user_role.dart';

class _StubUser {
  _StubUser(this.password, this.role, {this.candidate, this.recruiter});
  final String password;
  final UserRole role;
  final CandidateProfile? candidate;
  final RecruiterProfile? recruiter;
}

/// Proveedor de autenticación en memoria (sin backend).
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  final Map<String, _StubUser> _users = {};
  int _seq = 0;

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

  Future<void> _init() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    _initialized = true;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    await _wait();
    final user = _users[_key(email)];
    if (user == null || user.password != password) {
      return _fail('Correo o contraseña incorrectos');
    }
    _setSession(user);
    return _done();
  }

  Future<bool> signUpCandidate({
    required String nombre,
    required String email,
    required String password,
    required String ciudad,
    required DateTime fechaNacimiento,
    String? resumenPerfil,
  }) async {
    await _wait();
    final key = _key(email);
    if (_users.containsKey(key)) {
      return _fail('Este correo ya está registrado');
    }
    final profile = CandidateProfile(
      id: 'stub-${++_seq}',
      nombre: nombre.trim(),
      email: email.trim(),
      ciudad: ciudad.trim(),
      fechaNacimiento: fechaNacimiento,
      resumenPerfil: resumenPerfil?.trim(),
    );
    final user = _StubUser(password, UserRole.candidato, candidate: profile);
    _users[key] = user;
    _setSession(user);
    return _done();
  }

  Future<bool> signUpRecruiter({
    required String nombre,
    required String email,
    required String password,
    required String empresaNombre,
    required String empresaDescripcion,
    required String empresaMonograma,
  }) async {
    await _wait();
    final key = _key(email);
    if (_users.containsKey(key)) {
      return _fail('Este correo ya está registrado');
    }
    final profile = RecruiterProfile(
      id: 'stub-${++_seq}',
      nombre: nombre.trim(),
      email: email.trim(),
      empresa: Company(
        id: 'stub-co-$_seq',
        nombre: empresaNombre.trim(),
        descripcion: empresaDescripcion.trim(),
        monograma: empresaMonograma.trim(),
      ),
    );
    final user = _StubUser(password, UserRole.reclutador, recruiter: profile);
    _users[key] = user;
    _setSession(user);
    return _done();
  }

  Future<void> signOut() async {
    _role = null;
    _candidate = null;
    _recruiter = null;
    _error = null;
    notifyListeners();
  }

  String _key(String email) => email.trim().toLowerCase();

  Future<void> _wait() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _setSession(_StubUser user) {
    _role = user.role;
    _candidate = user.candidate;
    _recruiter = user.recruiter;
  }

  bool _fail(String message) {
    _loading = false;
    _error = message;
    notifyListeners();
    return false;
  }

  bool _done() {
    _loading = false;
    notifyListeners();
    return true;
  }
}
