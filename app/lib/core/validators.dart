/// Validadores de formularios. Devuelven null si el valor es válido o el
/// mensaje de error (en español) si no lo es.
class Validators {
  Validators._();

  static final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!_emailRe.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    return null;
  }

  static String? required(String? value, [String? campo]) {
    if (value == null || value.trim().isEmpty) {
      return campo == null ? 'Este campo es obligatorio' : 'Completa el campo $campo';
    }
    return null;
  }

  /// Fecha válida y no futura. Acepta null (sin fecha elegida).
  static String? date(DateTime? value, [DateTime? hoy]) {
    if (value == null) return 'Selecciona una fecha';
    final now = hoy ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (DateTime(value.year, value.month, value.day).isAfter(today)) {
      return 'La fecha no puede ser futura';
    }
    return null;
  }
}
