import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_failure.dart';
import 'auth_repository.dart';
import 'candidate_profile.dart';
import 'company.dart';
import 'recruiter_profile.dart';
import 'user_role.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static const _perfilNoEncontrado = AuthFailure('No encontramos tu perfil. Contacta a soporte');

  @override
  Stream<void> get onSignedOut => _auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.signedOut)
      .map((_) {});

  @override
  Future<SessionData?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null || _auth.currentSession == null) return null;
    try {
      return await _loadSession(user);
    } on AuthFailure {
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<SessionData> signIn(String email, String password) async {
    final res = await _auth.signInWithPassword(email: email.trim(), password: password);
    final user = res.user;
    if (user == null) {
      throw const AuthFailure('No se pudo iniciar sesión. Inténtalo de nuevo');
    }
    try {
      return await _loadSession(user);
    } on AuthFailure {
      await _auth.signOut();
      rethrow;
    }
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
    final user = await _createAccount(email, password, UserRole.candidato);
    final resumen = resumenPerfil?.trim();
    final resumenFinal = (resumen == null || resumen.isEmpty) ? null : resumen;
    try {
      await _client.from('usuarios').insert({
        'id': user.id,
        'nombre': nombre.trim(),
        'email': email.trim(),
        'ciudad': ciudad.trim(),
        'fecha_nacimiento': _fecha(fechaNacimiento),
        'resumen_perfil': resumenFinal,
      });
    } catch (_) {
      await _abortSignUp();
    }
    return SessionData.candidate(CandidateProfile(
      id: user.id,
      nombre: nombre.trim(),
      email: email.trim(),
      ciudad: ciudad.trim(),
      fechaNacimiento: fechaNacimiento,
      resumenPerfil: resumenFinal,
    ));
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
    final user = await _createAccount(email, password, UserRole.reclutador);
    try {
      await _client.rpc('registrar_reclutador', params: {
        'p_nombre': nombre.trim(),
        'p_email': email.trim(),
        'p_empresa_nombre': empresaNombre.trim(),
        'p_empresa_descripcion': empresaDescripcion.trim(),
        'p_empresa_monograma': empresaMonograma.trim(),
      });
    } catch (_) {
      await _abortSignUp();
    }
    return _loadSession(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<User> _createAccount(String email, String password, UserRole role) async {
    final res = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {'role': role.name},
    );
    final user = res.user;
    if (user == null || res.session == null) {
      throw const AuthFailure('No se pudo crear la cuenta. Inténtalo de nuevo');
    }
    return user;
  }

  /// La cuenta de Auth ya existe pero su perfil no se guardó: se cierra la
  /// sesión para no dejar al usuario a medias. Queda un usuario huérfano en
  /// Auth que solo se puede limpiar desde el dashboard.
  Future<Never> _abortSignUp() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    throw const AuthFailure(
      'Creamos tu cuenta pero no pudimos guardar tu perfil. Inténtalo de nuevo más tarde',
    );
  }

  Future<SessionData> _loadSession(User user) async {
    switch (_roleOf(user)) {
      case UserRole.candidato:
        final row = await _client.from('usuarios').select().eq('id', user.id).maybeSingle();
        if (row == null) throw _perfilNoEncontrado;
        return SessionData.candidate(CandidateProfile(
          id: row['id'] as String,
          nombre: row['nombre'] as String,
          email: row['email'] as String,
          ciudad: (row['ciudad'] as String?) ?? '',
          fechaNacimiento: DateTime.parse(row['fecha_nacimiento'] as String),
          resumenPerfil: row['resumen_perfil'] as String?,
        ));
      case UserRole.reclutador:
        final row = await _client
            .from('reclutadores')
            .select('id, nombre, email, empresas(id, nombre, descripcion, monograma)')
            .eq('id', user.id)
            .maybeSingle();
        final empresa = row?['empresas'] as Map<String, dynamic>?;
        if (row == null || empresa == null) throw _perfilNoEncontrado;
        return SessionData.recruiter(RecruiterProfile(
          id: row['id'] as String,
          nombre: row['nombre'] as String,
          email: row['email'] as String,
          empresa: Company(
            id: empresa['id'] as String,
            nombre: empresa['nombre'] as String,
            descripcion: (empresa['descripcion'] as String?) ?? '',
            monograma: (empresa['monograma'] as String?) ?? '',
          ),
        ));
    }
  }

  UserRole _roleOf(User user) {
    final raw = user.userMetadata?['role'];
    for (final r in UserRole.values) {
      if (r.name == raw) return r;
    }
    throw const AuthFailure('No pudimos identificar el tipo de tu cuenta');
  }

  String _fecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$mm-$dd';
  }
}
