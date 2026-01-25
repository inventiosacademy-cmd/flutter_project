import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/evaluation_upload.dart';

class EvaluationUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Pick PDF file from device
  Future<PlatformFile?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
  }

  /// Validate PDF file
  bool validatePdfFile(PlatformFile file) {
    // Check file extension
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw Exception('File harus berformat PDF');
    }
    
    // No size limit as per requirement
    return true;
  }

  /// Upload Evaluation PDF to Firebase Storage
  Future<EvaluationUpload> uploadEvaluationPdf({
    required String employeeId,
    required PlatformFile pdfFile,
    required int pkwtKe,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      // Validate file
      validatePdfFile(pdfFile);

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${pdfFile.name}';
      
      // Storage path: users/{userId}/employees/{employeeId}/evaluations/{fileName}
      final storageRef = _storage.ref().child('users/$userId/employees/$employeeId/evaluations/$fileName');

      // Upload file
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web platform
        if (pdfFile.bytes != null) {
          uploadTask = storageRef.putData(
            pdfFile.bytes!,
            SettableMetadata(contentType: 'application/pdf'),
          );
        } else {
          throw Exception('File data tidak tersedia');
        }
      } else {
        // For mobile/desktop platforms
        if (pdfFile.path != null) {
          final file = File(pdfFile.path!);
          uploadTask = storageRef.putFile(
            file,
            SettableMetadata(contentType: 'application/pdf'),
          );
        } else {
          throw Exception('File path tidak tersedia');
        }
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create EvaluationUpload object
      final evaluationUpload = EvaluationUpload(
        id: fileName, // Using filename as ID
        employeeId: employeeId,
        fileName: pdfFile.name,
        fileUrl: downloadUrl,
        uploadedAt: DateTime.now(),
        fileSize: pdfFile.size,
        pkwtKe: pkwtKe,
      );

      return evaluationUpload;
    } catch (e) {
      debugPrint('Error uploading PDF: $e');
      rethrow;
    }
  }

  /// Download/Open PDF in browser
  Future<void> downloadPdf(String url, String filename) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Tidak dapat membuka PDF');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }
}
