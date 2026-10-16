class CandidateProfile {
  const CandidateProfile({
    required this.id,
    required this.nombre,
    required this.email,
    required this.ciudad,
    required this.fechaNacimiento,
    this.resumenPerfil,
  });

  final String id;
  final String nombre;
  final String email;
  final String ciudad;
  final DateTime fechaNacimiento;
  final String? resumenPerfil;
}
