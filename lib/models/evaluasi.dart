enum EvaluasiStatus {
  draft,
  belumTTD,
  selesai,
}

extension EvaluasiStatusExtension on EvaluasiStatus {
  String get label {
    switch (this) {
      case EvaluasiStatus.draft:
        return 'Draft';
      case EvaluasiStatus.belumTTD:
        return 'Belum TTD Atasan';
      case EvaluasiStatus.selesai:
        return 'Selesai';
    }
  }
}

class Evaluasi {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeePosition;
  final DateTime tanggalEvaluasi;
  final String periode;
  final String nilaiKinerja;
  final String catatan;
  final EvaluasiStatus status;
  final String evaluator;
  final DateTime createdAt;
  final DateTime updatedAt;

  Evaluasi({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeePosition,
    required this.tanggalEvaluasi,
    required this.periode,
    required this.nilaiKinerja,
    required this.catatan,
    required this.status,
    required this.evaluator,
    required this.createdAt,
    required this.updatedAt,
  });

  Evaluasi copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeePosition,
    DateTime? tanggalEvaluasi,
    String? periode,
    String? nilaiKinerja,
    String? catatan,
    EvaluasiStatus? status,
    String? evaluator,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Evaluasi(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeePosition: employeePosition ?? this.employeePosition,
      tanggalEvaluasi: tanggalEvaluasi ?? this.tanggalEvaluasi,
      periode: periode ?? this.periode,
      nilaiKinerja: nilaiKinerja ?? this.nilaiKinerja,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      evaluator: evaluator ?? this.evaluator,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
