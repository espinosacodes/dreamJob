import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_failure.dart';

const _sinConexion = 'Sin conexión. Revisa tu internet e inténtalo de nuevo';
const _yaRegistrado = 'Este correo ya está registrado';
const _credenciales = 'Correo o contraseña incorrectos';
const _contrasenaDebil = 'La contraseña es muy débil. Usa al menos 8 caracteres';
const _demasiadosIntentos = 'Demasiados intentos. Espera un momento e inténtalo de nuevo';
const _generico = 'Ocurrió un error inesperado. Inténtalo de nuevo';

/// Traduce cualquier error de red, Auth o base de datos a un mensaje en
/// español. Nunca devuelve el texto crudo de Supabase.
String mapAuthError(Object error) {
  if (error is AuthFailure) return error.message;

  if (error is SocketException ||
      error is TimeoutException ||
      error is AuthRetryableFetchException ||
      error.runtimeType.toString() == 'ClientException') {
    return _sinConexion;
  }

  if (error is AuthException) return _mapAuthException(error);

  if (error is PostgrestException) {
    switch (error.code) {
      case '23505':
        return _yaRegistrado;
      case '42501':
      case 'PGRST301':
        return 'No tienes permiso para realizar esta acción';
    }
    return _generico;
  }

  return _generico;
}

String _mapAuthException(AuthException error) {
  switch (error.code) {
    case 'user_already_exists':
    case 'email_exists':
      return _yaRegistrado;
    case 'invalid_credentials':
      return _credenciales;
    case 'weak_password':
      return _contrasenaDebil;
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return _demasiadosIntentos;
    case 'email_address_invalid':
    case 'validation_failed':
      return 'Revisa que el correo y la contraseña sean válidos';
  }

  final msg = error.message.toLowerCase();
  if (msg.contains('already registered') || msg.contains('already been registered')) {
    return _yaRegistrado;
  }
  if (msg.contains('invalid login credentials')) return _credenciales;
  if (msg.contains('password') && (msg.contains('least') || msg.contains('weak') || msg.contains('short'))) {
    return _contrasenaDebil;
  }
  if (msg.contains('rate limit')) return _demasiadosIntentos;
  if (msg.contains('failed host lookup') || msg.contains('socket')) return _sinConexion;
  return _generico;
}
