import 'uploaded_document.dart';

/// Model untuk dokumen PKWT
/// Extends UploadedDocument untuk menghindari duplikasi kode
class PkwtDocument extends UploadedDocument {
  const PkwtDocument({
    required super.id,
    required super.employeeId,
    required super.fileName,
    required super.fileUrl,
    required super.uploadedAt,
    required super.fileSize,
    required super.pkwtKe,
  });

  factory PkwtDocument.fromMap(Map<String, dynamic> map) {
    return PkwtDocument(
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
