import 'uploaded_document.dart';

/// Model untuk dokumen evaluasi yang di-upload
/// Extends UploadedDocument untuk menghindari duplikasi kode
class EvaluationUpload extends UploadedDocument {
  const EvaluationUpload({
    required super.id,
    required super.employeeId,
    required super.fileName,
    required super.fileUrl,
    required super.uploadedAt,
    required super.fileSize,
    required super.pkwtKe,
  });

  factory EvaluationUpload.fromMap(Map<String, dynamic> map) {
    return EvaluationUpload(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      uploadedAt: DateTime.tryParse(map['uploadedAt'] ?? '') ?? DateTime.now(),
      fileSize: map['fileSize'] ?? 0,
      pkwtKe: map['pkwtKe'] ?? 1,
    );
  }
}
