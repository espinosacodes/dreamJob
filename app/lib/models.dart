class JobItem {
  final String title;
  final String company;
  final String mono;
  final String photo;
  final String location;
  final String comp;
  final String compProv;
  final String posted;
  final List<String> stack;
  final List<String> bullets;
  final List<String> reasons;
  final String? warning;
  const JobItem({
    required this.title,
    required this.company,
    required this.mono,
    required this.photo,
    required this.location,
    required this.comp,
    required this.compProv,
    required this.posted,
    required this.stack,
    required this.bullets,
    required this.reasons,
    this.warning,
  });
}
