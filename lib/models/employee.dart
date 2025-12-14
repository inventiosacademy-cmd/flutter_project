import 'package:intl/intl.dart';

class Employee {
  final String id;
  final String nama;
  final String jenisKelamin;
  final String tempatLahir;
  final DateTime tglLahir;
  final String alamat;
  final String noHp;
  final String email;
  final String ktp;
  final String npwp;
  final DateTime tglMulai;
  final DateTime tglSelesai;

  Employee({
    required this.id,
    required this.nama,
    required this.jenisKelamin,
    required this.tempatLahir,
    required this.tglLahir,
    required this.alamat,
    required this.noHp,
    required this.email,
    required this.ktp,
    required this.npwp,
    required this.tglMulai,
    required this.tglSelesai,
  });

  // Getter untuk Masa Kerja (format string: "X Tahun Y Bulan")
  String get masaKerja {
    final now = DateTime.now();
    int years = now.year - tglMulai.year;
    int months = now.month - tglMulai.month;
    int days = now.day - tglMulai.day;

    if (months < 0 || (months == 0 && days < 0)) {
      years--;
      months += 12;
    }

    if (days < 0) {
      months--;
      // Simple approximation for days in previous month
      days += 30; 
    }
    
    // Adjust logic if months becomes negative after day adjustment
     if (months < 0) {
       years--;
       months +=12;
     }

    return "$years Tahun $months Bulan";
  }

  // Getter durasi dalam hari menuju expired
  int get hariMenujuExpired {
    final now = DateTime.now();
    // Normalize dates to ignore time component for accurate day calculation
    final dateNow = DateTime(now.year, now.month, now.day);
    final dateEnd = DateTime(tglSelesai.year, tglSelesai.month, tglSelesai.day);
    
    return dateEnd.difference(dateNow).inDays;
  }
}
