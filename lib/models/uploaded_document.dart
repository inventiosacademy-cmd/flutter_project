/// Base class untuk dokumen yang di-upload ke Firebase Storage
/// Digunakan oleh PkwtDocument dan EvaluationUpload
class UploadedDocument {
  final String id;
  final String employeeId;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final int fileSize;
  final int pkwtKe;

  const UploadedDocument({
    required this.id,
    required this.employeeId,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    required this.fileSize,
    required this.pkwtKe,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'fileSize': fileSize,
      'pkwtKe': pkwtKe,
    };
  }

  /// Helper method untuk format ukuran file
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
