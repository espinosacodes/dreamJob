import 'package:flutter_test/flutter_test.dart';

import 'package:dreamjob/auth/auth.dart';
import 'package:dreamjob/auth/data/in_memory_auth_repository.dart';

AuthProvider _provider() => AuthProvider(
      repository: InMemoryAuthRepository(
        latency: Duration.zero,
        restoreDelay: Duration.zero,
      ),
    );

Future<void> _ready(AuthProvider auth) async {
  while (!auth.initialized) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<bool> _registrarCandidato(AuthProvider auth, String email) {
  return auth.signUpCandidate(
    nombre: 'Ana Pérez',
    email: email,
    password: 'clave1234',
    ciudad: 'Bogotá',
    fechaNacimiento: DateTime(2000, 5, 4),
  );
}

void main() {
  test('arranca sin sesión', () async {
    final auth = _provider();
    await _ready(auth);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.role, isNull);
  });

  test('registra un candidato y abre sesión', () async {
    final auth = _provider();
    await _ready(auth);
    expect(await _registrarCandidato(auth, 'ana@mail.com'), isTrue);
    expect(auth.role, UserRole.candidato);
    expect(auth.candidate?.nombre, 'Ana Pérez');
    expect(auth.recruiter, isNull);
    expect(auth.error, isNull);
  });

  test('registra un reclutador con su empresa', () async {
    final auth = _provider();
    await _ready(auth);
    final ok = await auth.signUpRecruiter(
      nombre: 'Luis Gómez',
      email: 'luis@empresa.com',
      password: 'clave1234',
      empresaNombre: 'Acme',
      empresaDescripcion: 'Software',
      empresaMonograma: 'AC',
    );
    expect(ok, isTrue);
    expect(auth.role, UserRole.reclutador);
    expect(auth.recruiter?.empresa.nombre, 'Acme');
    expect(auth.candidate, isNull);
  });

  test('correo repetido devuelve error en español', () async {
    final auth = _provider();
    await _ready(auth);
    await _registrarCandidato(auth, 'ana@mail.com');
    await auth.signOut();
    expect(await _registrarCandidato(auth, 'ANA@mail.com'), isFalse);
    expect(auth.error, 'Este correo ya está registrado');
    expect(auth.isAuthenticated, isFalse);
  });

  test('credenciales incorrectas', () async {
    final auth = _provider();
    await _ready(auth);
    await _registrarCandidato(auth, 'ana@mail.com');
    await auth.signOut();
    expect(await auth.signIn('ana@mail.com', 'otra-clave'), isFalse);
    expect(auth.error, 'Correo o contraseña incorrectos');
    expect(await auth.signIn('ana@mail.com', 'clave1234'), isTrue);
    expect(auth.error, isNull);
  });

  test('signOut limpia el estado', () async {
    final auth = _provider();
    await _ready(auth);
    await _registrarCandidato(auth, 'ana@mail.com');
    await auth.signOut();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.candidate, isNull);
  });
}
