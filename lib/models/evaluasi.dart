class Evaluation {
  final String id;
  final String employeeId;
  final DateTime date;
  final String notes;
  final double score; // Skala 1-100 atau 1-5

  Evaluation({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.notes,
    required this.score,
  });
}
