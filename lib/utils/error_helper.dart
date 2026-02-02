import 'package:flutter/foundation.dart';

/// Utility class untuk mengkonversi error ke pesan bahasa Indonesia
/// Digunakan oleh semua providers untuk konsistensi error messages
class ErrorHelper {
  /// Konversi error ke pesan bahasa Indonesia yang user-friendly
  static String getErrorMessage(dynamic e, {String context = ''}) {
    final errorStr = e.toString().toLowerCase();
    
    // Firebase Auth errors
    if (errorStr.contains('user-not-found') || 
        errorStr.contains('wrong-password') || 
        errorStr.contains('invalid-credential') ||
        errorStr.contains('invalid-login-credentials')) {
      return 'Email atau password salah.';
    }
    
    if (errorStr.contains('invalid-email')) {
      return 'Format email tidak valid.';
    }
    
    if (errorStr.contains('user-disabled')) {
      return 'Akun ini telah dinonaktifkan. Hubungi administrator.';
    }
    
    if (errorStr.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Silakan tunggu beberapa menit.';
    }
    
    // Firestore errors
    if (errorStr.contains('permission-denied')) {
      return 'Akses ditolak. Anda tidak memiliki izin untuk operasi ini.';
    }
    
    if (errorStr.contains('not-found')) {
      return context.isNotEmpty 
          ? '$context tidak ditemukan.' 
          : 'Data tidak ditemukan.';
    }
    
    if (errorStr.contains('already-exists')) {
      return context.isNotEmpty 
          ? '$context sudah ada.' 
          : 'Data dengan ID tersebut sudah ada.';
    }
    
    // Network errors
    if (errorStr.contains('unavailable') || 
        errorStr.contains('network') ||
        errorStr.contains('network-request-failed')) {
      return 'Tidak ada koneksi internet. Periksa koneksi Anda.';
    }
    
    if (errorStr.contains('deadline-exceeded') || errorStr.contains('timeout')) {
      return 'Koneksi timeout. Silakan coba lagi.';
    }
    
    // Auth state errors
    if (errorStr.contains('unauthenticated') || 
        errorStr.contains('user belum login') ||
        errorStr.contains('user not logged in')) {
      return 'Sesi login telah berakhir. Silakan login kembali.';
    }
    
    // Storage errors
    if (errorStr.contains('quota-exceeded') || errorStr.contains('storage')) {
      return 'Kuota penyimpanan habis. Hubungi administrator.';
    }
    
    // Operation errors
    if (errorStr.contains('cancelled')) {
      return 'Operasi dibatalkan.';
    }
    
    if (errorStr.contains('operation-not-allowed')) {
      return 'Operasi ini tidak diizinkan.';
    }
    
    // Log unknown errors
    debugPrint('Unhandled error: $e');
    
    // Default message
    return context.isNotEmpty 
        ? 'Gagal $context. Silakan coba lagi.'
        : 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
