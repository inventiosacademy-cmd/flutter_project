import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../models/karyawan.dart';

/// Data class untuk menyimpan hasil evaluasi lengkap
class EvaluasiData {
  final String namaKaryawan;
  final String posisi;
  final String departemen;
  final String lokasiKerja;
  final String atasanLangsung;
  final DateTime tanggalMasuk;
  final DateTime tanggalPkwtBerakhir;
  final int pkwtKe;
  final DateTime tanggalEvaluasi;
  
  // Ketidakhadiran
  final int sakit;
  final int izin;
  final int terlambat;
  final int mangkir;
  
  // Penilaian (map of factor index to rating: 5=BS, 4=SB, 3=B, 2=K, 1=KS, 0=NA)
  final Map<int, int?> ratings;
  final Map<int, String> comments;
  
  // Rekomendasi
  final String recommendation; // 'perpanjang', 'permanen', 'berakhir'
  final int perpanjangBulan;
  final String catatan;
  
  // Evaluator info
  final String namaEvaluator;
  
  // Signatures (base64 encoded images)
  final String? signatureBase64; // Employee signature
  final String hcgsAdminName; // HCGS admin name
  final String? hcgsSignatureBase64; // HCGS signature
  
  EvaluasiData({
    required this.namaKaryawan,
    required this.posisi,
    required this.departemen,
    required this.lokasiKerja,
    required this.atasanLangsung,
    required this.tanggalMasuk,
    required this.tanggalPkwtBerakhir,
    required this.pkwtKe,
    required this.tanggalEvaluasi,
    this.sakit = 0,
    this.izin = 0,
    this.terlambat = 0,
    this.mangkir = 0,
    required this.ratings,
    required this.comments,
    required this.recommendation,
    this.perpanjangBulan = 6,
    this.catatan = '',
    required this.namaEvaluator,
    this.signatureBase64,
    this.hcgsAdminName = '',
    this.hcgsSignatureBase64,
  });
  
  factory EvaluasiData.fromEmployee(Employee employee, {
    required Map<int, int?> ratings,
    required Map<int, String> comments,
    required String recommendation,
    int perpanjangBulan = 6,
    String catatan = '',
    String namaEvaluator = '',
    int sakit = 0,
    int izin = 0,
    int terlambat = 0,
    int mangkir = 0,
  }) {
    return EvaluasiData(
      namaKaryawan: employee.nama,
      posisi: employee.posisi,
      departemen: employee.departemen,
      lokasiKerja: employee.departemen, // Using departemen as lokasi for now
      atasanLangsung: employee.atasanLangsung,
      tanggalMasuk: employee.tglMasuk,
      tanggalPkwtBerakhir: employee.tglPkwtBerakhir,
      pkwtKe: employee.pkwtKe,
      tanggalEvaluasi: DateTime.now(),
      sakit: sakit,
      izin: izin,
      terlambat: terlambat,
      mangkir: mangkir,
      ratings: ratings,
      comments: comments,
      recommendation: recommendation,
      perpanjangBulan: perpanjangBulan,
      catatan: catatan,
      namaEvaluator: namaEvaluator,
      signatureBase64: null, // Will be set separately if needed
    );
  }
  
  int get totalNilai {
    int total = 0;
    for (var r in ratings.values) {
      if (r != null && r > 0) total += r;
    }
    return total;
  }
  
  int get totalFaktor {
    int count = 0;
    for (var r in ratings.values) {
      if (r != null && r > 0) count++;
    }
    return count;
  }
  
  double get nilaiRataRata {
    if (totalFaktor == 0) return 0;
    return totalNilai / totalFaktor;
  }
  
  bool get isLulus => nilaiRataRata >= 3;
}

/// Generator PDF untuk form Evaluasi PKWT
class EvaluasiPdfGenerator {
  static const List<String> factors = [
    'Kemampuan Adaptasi',
    'Kemampuan Bekerja',
    'Kemampuan bekerjasama dengan orang lain',
    'Inisiatif',
    'Kemampuan mengambil keputusan',
    'Sikap dan Perilaku',
    'Kontribusi dalam pekerjaan',
    'Kerajinan',
    'Kreatifitas',
    'Kepemimpinan',
    'Kemampuan Komunikasi',
    'Perencanaan',
    'Kapasitas',
    'Others',
  ];

  static Future<Uint8List> generatePdf(EvaluasiData data) async {
    final pdf = pw.Document();
    
    // Load fonts
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    
    // Load logo image
    final logoImage = await rootBundle.load('assets/logo_bm.png');
    final logoImageBytes = logoImage.buffer.asUint8List();
    final logo = pw.MemoryImage(logoImageBytes);
    
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Colors
    final headerColor = PdfColor.fromHex('#8B0000'); // Dark red
    final borderColor = PdfColors.grey400;
    
    // Styles
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 14, color: headerColor);
    final labelStyle = pw.TextStyle(font: fontBold, fontSize: 9);
    final valueStyle = pw.TextStyle(font: fontRegular, fontSize: 9);
    final smallStyle = pw.TextStyle(font: fontRegular, fontSize: 8);
    final smallBoldStyle = pw.TextStyle(font: fontBold, fontSize: 8);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // HEADER
          _buildHeader(headerStyle, labelStyle, valueStyle, borderColor, logo),
          pw.SizedBox(height: 16),
          
          // EMPLOYEE INFO
          _buildEmployeeInfo(data, labelStyle, valueStyle),
          pw.SizedBox(height: 16),
          
          // DATES
          _buildDatesSection(data, labelStyle, valueStyle, borderColor, dateFormat),
          pw.SizedBox(height: 16),
          
          // KETIDAKHADIRAN
          _buildKetidakhadiranSection(data, labelStyle, valueStyle, borderColor),
          pw.SizedBox(height: 16),
          
          // INSTRUKSI
          _buildInstruksiSection(labelStyle, smallStyle, smallBoldStyle, borderColor),
          pw.SizedBox(height: 16),
          
          // EVALUATION TABLE
          _buildEvaluationTable(data, labelStyle, smallStyle, smallBoldStyle, borderColor),
          pw.SizedBox(height: 16),
          
          // REKOMENDASI
          _buildRekomendasiSection(data, labelStyle, valueStyle),
          pw.SizedBox(height: 16),
          
          // CATATAN
          if (data.catatan.isNotEmpty)
            _buildCatatanSection(data, labelStyle, valueStyle, borderColor),
          pw.SizedBox(height: 24),
          
          // SIGNATURES
          _buildSignatureSection(data, labelStyle, valueStyle, smallStyle, dateFormat),
        ],
      ),
    );
    
    return pdf.save();
  }
  
  static pw.Widget _buildHeader(
    pw.TextStyle headerStyle,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    PdfColor borderColor,
    pw.MemoryImage logo,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo
        pw.Container(
          width: 60,
          height: 60,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(width: 16),
        // Title
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Evaluasi PKWT', style: headerStyle),
              pw.Text('(Karyawan Kontrak)', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        // Document info
        pw.Container(
          width: 150,
          child: pw.Table(
            border: pw.TableBorder.all(color: borderColor),
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nomor Dokumen', style: labelStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(':', style: valueStyle)),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tanggal Dokumen', style: labelStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(':', style: valueStyle)),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Status', style: labelStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(': Rahasia', style: valueStyle)),
              ]),
            ],
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildEmployeeInfo(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Column(
      children: [
        _buildInfoRow('Nama', data.namaKaryawan, labelStyle, valueStyle),
        _buildInfoRow('Posisi/ Jabatan', data.posisi, labelStyle, valueStyle),
        _buildInfoRow('Departemen', data.departemen, labelStyle, valueStyle),
        _buildInfoRow('Lokasi Kerja', data.lokasiKerja, labelStyle, valueStyle),
        _buildInfoRow('Atasan Langsung', data.atasanLangsung, labelStyle, valueStyle),
      ],
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: labelStyle)),
          pw.Text(': ', style: valueStyle),
          pw.Expanded(child: pw.Text(value, style: valueStyle)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildDatesSection(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    PdfColor borderColor,
    DateFormat dateFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Tanggal Masuk Kerja', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Tanggal berakhir PKWT', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Tanggal Evaluasi', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(dateFormat.format(data.tanggalMasuk), style: valueStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${dateFormat.format(data.tanggalPkwtBerakhir)} (ke - ${data.pkwtKe})', style: valueStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(dateFormat.format(data.tanggalEvaluasi), style: valueStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildKetidakhadiranSection(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    PdfColor borderColor,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Ketidakhadiran selama\nmasa penilaian PKWT\n(kontrak)', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Jumlah\nKetidakhadiran', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        _buildKetidakhadiranRow('Sakit', data.sakit.toString(), valueStyle),
        _buildKetidakhadiranRow('Izin', data.izin.toString(), valueStyle),
        _buildKetidakhadiranRow('Terlambat', data.terlambat.toString(), valueStyle),
        _buildKetidakhadiranRow('Alpa (Mangkir)', data.mangkir.toString(), valueStyle),
      ],
    );
  }
  
  static pw.TableRow _buildKetidakhadiranRow(String label, String value, pw.TextStyle style) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(label, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(value, style: style, textAlign: pw.TextAlign.center)),
      ],
    );
  }
  
  static pw.Widget _buildInstruksiSection(
    pw.TextStyle labelStyle,
    pw.TextStyle smallStyle,
    pw.TextStyle smallBoldStyle,
    PdfColor borderColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('INSTRUKSI:', style: labelStyle),
        pw.SizedBox(height: 4),
        pw.Text('1. Gunakan salah satu dari peringkat berikut untuk menggambarkan kinerja karyawan masa kontrak:', style: smallStyle),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nilai', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Rating Description', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Rating Explanation', style: smallBoldStyle)),
              ],
            ),
            _buildRatingRow('5', 'BS : Baik Sekali', 'Secara konsisten, mampu bekerja melebihi harapan.', smallStyle),
            _buildRatingRow('4', 'SB : Sangat Baik', 'Seringkali bekerja melebihi harapan.', smallStyle),
            _buildRatingRow('3', 'B : Baik', 'Secara konsisten, mampu bekerja sesuai harapan.', smallStyle),
            _buildRatingRow('2', 'K : Kurang', 'Kadang-kadang bisa bekerja sesuai harapan.', smallStyle),
            _buildRatingRow('1', 'KS : Kurang Sekali', 'Tidak mampu bekerja sesuai harapan.', smallStyle),
            _buildRatingRow('NA', 'Tidak digunakan', 'Tidak dinilai', smallStyle),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text('2. Hasil evaluasi masa kontrak untuk karyawan baru adalah sebagai berikut:', style: smallStyle),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No.', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Hasil Evaluasi', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nilai Rata-rata', style: smallBoldStyle)),
              ],
            ),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('1.', style: smallStyle, textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Lulus', style: smallStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('>= 3   Diatas atau sama dengan 3 (tiga)', style: smallStyle)),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('2.', style: smallStyle, textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tidak Lulus', style: smallStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('< 3   Dibawah 3 (tiga)', style: smallStyle)),
            ]),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text('3. Rata-rata menggunakan rumus berikut:', style: smallStyle),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor)),
          child: pw.Row(
            children: [
              pw.Text('R = TN/F', style: smallBoldStyle),
              pw.SizedBox(width: 40),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('R = Nilai Rata-rata', style: smallStyle),
                  pw.Text('TN = Jumlah Total Nilai', style: smallStyle),
                  pw.Text('F = Total Faktor yang dinilai', style: smallStyle),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  static pw.TableRow _buildRatingRow(String nilai, String desc, String explanation, pw.TextStyle style) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(nilai, style: style, textAlign: pw.TextAlign.center)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(desc, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(explanation, style: style)),
      ],
    );
  }
  
  static pw.Widget _buildEvaluationTable(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle smallStyle,
    pw.TextStyle smallBoldStyle,
    PdfColor borderColor,
  ) {
    // Count ratings per value
    Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0, 0: 0};
    for (var r in data.ratings.values) {
      if (r != null) {
        ratingCounts[r] = (ratingCounts[r] ?? 0) + 1;
      }
    }
    
    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: borderColor),
          columnWidths: {
            0: const pw.FixedColumnWidth(25),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(25),
            3: const pw.FixedColumnWidth(25),
            4: const pw.FixedColumnWidth(25),
            5: const pw.FixedColumnWidth(25),
            6: const pw.FixedColumnWidth(25),
            7: const pw.FixedColumnWidth(30),
            8: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Faktor yang dinilai', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('BS\n(5)', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('SB\n(4)', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('B\n(3)', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('K\n(2)', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('KS\n(1)', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('NA (-)', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Komentar', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
              ],
            ),
            // Factor rows
            ...List.generate(factors.length, (index) {
              int? rating = data.ratings[index];
              String comment = data.comments[index] ?? '';
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${index + 1}', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(factors[index], style: smallStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rating == 5 ? 'V' : '', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rating == 4 ? 'V' : '', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rating == 3 ? 'V' : '', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rating == 2 ? 'V' : '', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rating == 1 ? 'V' : '', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rating == 0 ? 'V' : '', style: smallStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(comment, style: smallStyle)),
                ],
              );
            }),
            // Total per item row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('TOTAL NILAI PER ITEM', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${ratingCounts[5]}', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${ratingCounts[4]}', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${ratingCounts[3]}', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${ratingCounts[2]}', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${ratingCounts[1]}', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${ratingCounts[0]}', style: smallBoldStyle, textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
              ],
            ),
            // Total semua nilai row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('TOTAL SEMUA NILAI', style: smallBoldStyle)),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${data.totalNilai}', style: smallBoldStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('', style: smallBoldStyle)),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildRekomendasiSection(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('REKOMENDASI', style: labelStyle),
        pw.SizedBox(width: 40),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: data.recommendation == 'perpanjang' 
                    ? pw.Center(child: pw.Text('V', style: pw.TextStyle(fontSize: 8)))
                    : pw.Container(),
                ),
                pw.SizedBox(width: 8),
                pw.Text('Perpanjang Kontrak ', style: valueStyle),
                pw.Container(
                  width: 30,
                  decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black))),
                  child: pw.Text('${data.perpanjangBulan}', style: valueStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Text(' Bulan', style: valueStyle),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: data.recommendation == 'permanen' 
                    ? pw.Center(child: pw.Text('V', style: pw.TextStyle(fontSize: 8)))
                    : pw.Container(),
                ),
                pw.SizedBox(width: 8),
                pw.Text('Permanen', style: valueStyle),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: data.recommendation == 'berakhir' 
                    ? pw.Center(child: pw.Text('V', style: pw.TextStyle(fontSize: 8)))
                    : pw.Container(),
                ),
                pw.SizedBox(width: 8),
                pw.Text('Kontrak Berakhir', style: valueStyle),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildCatatanSection(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    PdfColor borderColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CATATAN:', style: labelStyle),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor),
          ),
          child: pw.Text(data.catatan, style: valueStyle),
        ),
      ],
    );
  }
  
  static pw.Widget _buildSignatureSection(
    EvaluasiData data,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    pw.TextStyle smallStyle,
    DateFormat dateFormat,
  ) {
    // Convert base64 signatures to images if available
    pw.MemoryImage? signatureImage;
    pw.MemoryImage? hcgsSignatureImage;
    
    if (data.signatureBase64 != null && data.signatureBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(data.signatureBase64!);
        signatureImage = pw.MemoryImage(bytes);
      } catch (e) {
        // If decode fails, signatureImage stays null
      }
    }
    
    if (data.hcgsSignatureBase64 != null && data.hcgsSignatureBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(data.hcgsSignatureBase64!);
        hcgsSignatureImage = pw.MemoryImage(bytes);
      } catch (e) {
        // If decode fails, hcgsSignatureImage stays null
      }
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Diketahui oleh,', style: smallStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Disetujui oleh,', style: smallStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Diketahui oleh,', style: smallStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Disetujui oleh,', style: smallStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            // Employee signature column - show signature if available
            pw.Container(
              height: 50,
              child: signatureImage != null
                  ? pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                    )
                  : pw.Container(),
            ),
            pw.Container(height: 50), // Atasan Langsung
            // HCGS signature column - show signature if available
            pw.Container(
              height: 50,
              child: hcgsSignatureImage != null
                  ? pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(hcgsSignatureImage, fit: pw.BoxFit.contain),
                    )
                  : pw.Container(),
            ),
            pw.Container(height: 50), // Fungsional
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                children: [
                  pw.Text('(${data.namaKaryawan})', style: smallStyle),
                  pw.Text('Karyawan', style: smallStyle),
                  pw.Text('Tanggal:', style: smallStyle),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                children: [
                  pw.Text('(${data.atasanLangsung})', style: smallStyle),
                  pw.Text('Atasan Langsung', style: smallStyle),
                  pw.Text('Tanggal:', style: smallStyle),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                children: [
                  pw.Text(
                    '(${data.hcgsAdminName.isNotEmpty ? data.hcgsAdminName : "                    "})', 
                    style: smallStyle
                  ),
                  pw.Text('HCGS', style: smallStyle),
                  pw.Text('Tanggal:', style: smallStyle),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                children: [
                  pw.Text('(                    )', style: smallStyle),
                  pw.Text('Fungsional', style: smallStyle),
                  pw.Text('Tanggal:', style: smallStyle),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Save PDF and open in browser for preview
  static Future<String?> savePdfAndOpen(EvaluasiData data) async {
    final pdfData = await generatePdf(data);
    
    if (kIsWeb) {
      // On Web, using Printing.layoutPdf is the best way to allow users to save/print
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'evaluasi_${data.namaKaryawan.replaceAll(' ', '_')}.pdf',
      );
      return null; // No file path on web
    }
    
    // Get temp directory and save PDF (Native only)
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/evaluasi_${data.namaKaryawan.replaceAll(' ', '_')}_$timestamp.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfData);
    
    // Open in default app (browser/PDF viewer)
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    
    return filePath;
  }
  
  /// Print the PDF (legacy - goes to print dialog)
  static Future<void> printPdf(EvaluasiData data) async {
    final pdfData = await generatePdf(data);
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }
  
  /// Share the PDF
  static Future<void> sharePdf(EvaluasiData data, String filename) async {
    final pdfData = await generatePdf(data);
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }
}
