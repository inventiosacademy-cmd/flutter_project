class Employee {
  final String id;
  final String nama;
  final String posisi;
  final String departemen;
  final String atasanLangsung;
  final DateTime tglMasuk;
  final DateTime tglPkwtBerakhir;
  final int pkwtKe;

  Employee({
    required this.id,
    required this.nama,
    required this.posisi,
    required this.departemen,
    required this.atasanLangsung,
    required this.tglMasuk,
    required this.tglPkwtBerakhir,
    required this.pkwtKe,
  });

  // Getter untuk Masa Kerja (format string: "X Tahun Y Bulan")
  String get masaKerja {
    final now = DateTime.now();
    int years = now.year - tglMasuk.year;
    int months = now.month - tglMasuk.month;
    int days = now.day - tglMasuk.day;

    if (months < 0 || (months == 0 && days < 0)) {
      years--;
      months += 12;
    }

    if (days < 0) {
      months--;
      days += 30; 
    }
    
    if (months < 0) {
      years--;
      months += 12;
    }

    return "$years Tahun $months Bulan";
  }

  // Getter durasi dalam hari menuju PKWT expired
  int get hariMenujuExpired {
    final now = DateTime.now();
    final dateNow = DateTime(now.year, now.month, now.day);
    final dateEnd = DateTime(tglPkwtBerakhir.year, tglPkwtBerakhir.month, tglPkwtBerakhir.day);
    
    return dateEnd.difference(dateNow).inDays;
  }

  // Getter email placeholder (untuk kompatibilitas)
  String get email => "$nama@company.com".toLowerCase().replaceAll(' ', '.');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'posisi': posisi,
      'departemen': departemen,
      'atasanLangsung': atasanLangsung,
      'tglMasuk': tglMasuk.toIso8601String().split('T').first,
      'tglPkwtBerakhir': tglPkwtBerakhir.toIso8601String().split('T').first,
      'pkwtKe': pkwtKe,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      nama: map['nama'] ?? '',
      posisi: map['posisi'] ?? '',
      departemen: map['departemen'] ?? '',
      atasanLangsung: map['atasanLangsung'] ?? '',
      tglMasuk: DateTime.tryParse(map['tglMasuk'] ?? '') ?? DateTime.now(),
      tglPkwtBerakhir: DateTime.tryParse(map['tglPkwtBerakhir'] ?? '') ?? DateTime.now(),
      pkwtKe: map['pkwtKe'] ?? 1,
    );
  }
}
