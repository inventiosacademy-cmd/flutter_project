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
  final String employeeDepartemen;
  final String atasanLangsung;
  final DateTime tanggalMasuk;
  final DateTime tanggalPkwtBerakhir;
  final int pkwtKe;
  final DateTime tanggalEvaluasi;
  final String periode;
  final String nilaiKinerja;
  final String catatan;
  final EvaluasiStatus status;
  final String evaluator;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Ratings data (factor index -> rating value: 5=BS, 4=SB, 3=B, 2=K, 1=KS, 0=NA)
  final Map<int, int> ratings;
  final Map<int, String> comments;
  
  // Recommendation
  final String recommendation; // 'perpanjang', 'permanen', 'berakhir'
  final int perpanjangBulan;
  
  // Ketidakhadiran
  final int sakit;
  final int izin;
  final int terlambat;
  final int mangkir;
  
  // Signatures
  final String? signatureBase64; // Employee signature
  final String hcgsAdminName; // HCGS admin name
  final String? hcgsSignatureBase64; // HCGS signature

  Evaluasi({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeePosition,
    this.employeeDepartemen = '',
    this.atasanLangsung = '',
    DateTime? tanggalMasuk,
    DateTime? tanggalPkwtBerakhir,
    this.pkwtKe = 1,
    required this.tanggalEvaluasi,
    required this.periode,
    required this.nilaiKinerja,
    required this.catatan,
    required this.status,
    required this.evaluator,
    required this.createdAt,
    required this.updatedAt,
    Map<int, int>? ratings,
    Map<int, String>? comments,
    this.recommendation = 'perpanjang',
    this.perpanjangBulan = 6,
    this.sakit = 0,
    this.izin = 0,
    this.terlambat = 0,
    this.mangkir = 0,
    this.signatureBase64,
    this.hcgsAdminName = '',
    this.hcgsSignatureBase64,
  }) : 
    ratings = ratings ?? {},
    comments = comments ?? {},
    tanggalMasuk = tanggalMasuk ?? DateTime.now(),
    tanggalPkwtBerakhir = tanggalPkwtBerakhir ?? DateTime.now().add(const Duration(days: 180));

  Evaluasi copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeePosition,
    String? employeeDepartemen,
    String? atasanLangsung,
    DateTime? tanggalMasuk,
    DateTime? tanggalPkwtBerakhir,
    int? pkwtKe,
    DateTime? tanggalEvaluasi,
    String? periode,
    String? nilaiKinerja,
    String? catatan,
    EvaluasiStatus? status,
    String? evaluator,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<int, int>? ratings,
    Map<int, String>? comments,
    String? recommendation,
    int? perpanjangBulan,
    int? sakit,
    int? izin,
    int? terlambat,
    int? mangkir,
    String? signatureBase64,
    String? hcgsAdminName,
    String? hcgsSignatureBase64,
  }) {
    return Evaluasi(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeePosition: employeePosition ?? this.employeePosition,
      employeeDepartemen: employeeDepartemen ?? this.employeeDepartemen,
      atasanLangsung: atasanLangsung ?? this.atasanLangsung,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      tanggalPkwtBerakhir: tanggalPkwtBerakhir ?? this.tanggalPkwtBerakhir,
      pkwtKe: pkwtKe ?? this.pkwtKe,
      tanggalEvaluasi: tanggalEvaluasi ?? this.tanggalEvaluasi,
      periode: periode ?? this.periode,
      nilaiKinerja: nilaiKinerja ?? this.nilaiKinerja,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      evaluator: evaluator ?? this.evaluator,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ratings: ratings ?? this.ratings,
      comments: comments ?? this.comments,
      recommendation: recommendation ?? this.recommendation,
      perpanjangBulan: perpanjangBulan ?? this.perpanjangBulan,
      sakit: sakit ?? this.sakit,
      izin: izin ?? this.izin,
      terlambat: terlambat ?? this.terlambat,
      mangkir: mangkir ?? this.mangkir,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      hcgsAdminName: hcgsAdminName ?? this.hcgsAdminName,
      hcgsSignatureBase64: hcgsSignatureBase64 ?? this.hcgsSignatureBase64,
    );
  }
  
  // Convert ratings map to JSON-compatible format
  Map<String, int> get ratingsJson {
    return ratings.map((key, value) => MapEntry(key.toString(), value));
  }
  
  // Convert comments map to JSON-compatible format  
  Map<String, String> get commentsJson {
    return comments.map((key, value) => MapEntry(key.toString(), value));
  }
  
  // Create from JSON maps
  static Map<int, int> ratingsFromJson(Map<String, dynamic>? json) {
    if (json == null) return {};
    return json.map((key, value) => MapEntry(int.parse(key), value as int));
  }
  
  static Map<int, String> commentsFromJson(Map<String, dynamic>? json) {
    if (json == null) return {};
    return json.map((key, value) => MapEntry(int.parse(key), value as String));
  }
}
