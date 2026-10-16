import 'package:flutter_test/flutter_test.dart';

import 'package:dreamjob/core/validators.dart';

void main() {
  group('Validators.email', () {
    test('vacío o nulo pide el correo', () {
      expect(Validators.email(''), 'Ingresa tu correo');
      expect(Validators.email('   '), 'Ingresa tu correo');
      expect(Validators.email(null), 'Ingresa tu correo');
    });

    test('formato inválido', () {
      for (final v in ['juan', 'juan@', '@dominio.com', 'juan@dominio', 'a b@c.com']) {
        expect(Validators.email(v), isNotNull, reason: v);
      }
    });

    test('formato válido', () {
      expect(Validators.email('juan@dominio.com'), isNull);
      expect(Validators.email('  juan.perez@mail.co  '), isNull);
    });
  });

  group('Validators.password', () {
    test('vacía', () => expect(Validators.password(''), isNotNull));
    test('menos de 8 caracteres', () {
      expect(Validators.password('1234567'), isNotNull);
    });
    test('8 o más caracteres', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.required', () {
    test('vacío o solo espacios', () {
      expect(Validators.required(''), 'Este campo es obligatorio');
      expect(Validators.required('  '), 'Este campo es obligatorio');
      expect(Validators.required(null), 'Este campo es obligatorio');
    });

    test('usa el nombre del campo', () {
      expect(Validators.required('', 'ciudad'), 'Completa el campo ciudad');
    });

    test('con contenido', () => expect(Validators.required('Bogotá'), isNull));
  });

  group('Validators.date', () {
    final hoy = DateTime(2026, 10, 15);

    test('sin fecha', () => expect(Validators.date(null, hoy), isNotNull));
    test('fecha futura', () {
      expect(Validators.date(DateTime(2026, 10, 16), hoy), isNotNull);
    });
    test('hoy y pasado son válidos', () {
      expect(Validators.date(DateTime(2026, 10, 15, 23, 59), hoy), isNull);
      expect(Validators.date(DateTime(2000, 1, 1), hoy), isNull);
    });
  });
}
