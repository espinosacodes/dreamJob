import 'company.dart';

class RecruiterProfile {
  const RecruiterProfile({
    required this.id,
    required this.nombre,
    required this.email,
    required this.empresa,
  });

  final String id;
  final String nombre;
  final String email;
  final Company empresa;
}
