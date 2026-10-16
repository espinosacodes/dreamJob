import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dreamjob/core/auth_error_mapper.dart';
import 'package:dreamjob/core/auth_failure.dart';

void main() {
  test('correo ya registrado', () {
    expect(
      mapAuthError(const AuthApiException('User already registered', statusCode: '422', code: 'user_already_exists')),
      'Este correo ya está registrado',
    );
    expect(
      mapAuthError(const PostgrestException(message: 'duplicate key', code: '23505')),
      'Este correo ya está registrado',
    );
  });

  test('credenciales incorrectas', () {
    expect(
      mapAuthError(const AuthApiException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials')),
      'Correo o contraseña incorrectos',
    );
  });

  test('contraseña débil', () {
    expect(
      mapAuthError(const AuthApiException('Password should be at least 6 characters', statusCode: '422')),
      'La contraseña es muy débil. Usa al menos 8 caracteres',
    );
  });

  test('sin conexión', () {
    expect(mapAuthError(const SocketException('sin red')), startsWith('Sin conexión'));
    expect(mapAuthError(TimeoutException('lento')), startsWith('Sin conexión'));
    expect(mapAuthError(AuthRetryableFetchException(message: 'x')), startsWith('Sin conexión'));
  });

  test('AuthFailure conserva su mensaje', () {
    expect(mapAuthError(const AuthFailure('Mensaje propio')), 'Mensaje propio');
  });

  test('nunca expone el texto crudo', () {
    final msg = mapAuthError(Exception('relation "usuarios" does not exist'));
    expect(msg, 'Ocurrió un error inesperado. Inténtalo de nuevo');
    expect(msg, isNot(contains('usuarios')));
  });
}
