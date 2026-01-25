class EvaluationUpload {
  final String id;
  final String employeeId;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final int fileSize;
  final int pkwtKe;

  EvaluationUpload({
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

  // Helper method untuk format ukuran file
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
