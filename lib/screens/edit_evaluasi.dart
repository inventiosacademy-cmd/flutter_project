import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/evaluasi.dart';
import '../providers/prov_evaluasi.dart';
import '../theme/warna.dart';
import '../services/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../widgets/pdf_preview_dialog.dart';
import 'package:signature/signature.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class EditEvaluasiScreen extends StatefulWidget {
  final Evaluasi evaluasi;
  final VoidCallback onBack;
  
  const EditEvaluasiScreen({super.key, required this.evaluasi, required this.onBack});

  @override
  State<EditEvaluasiScreen> createState() => _EditEvaluasiScreenState();
}

class _EditEvaluasiScreenState extends State<EditEvaluasiScreen> {
  bool _isLoading = false;
  
  // List of evaluation factors
  final List<String> _factors = [
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
  
  // Rating values: 5=BS, 4=SB, 3=B, 2=K, 1=KS, 0=NA
  late Map<int, int?> _ratings;
  late Map<int, TextEditingController> _comments;
  
  // Recommendation
  late String _recommendation;
  late int _perpanjangBulan;
  late TextEditingController _notesController;
  late TextEditingController _periodeController;
  
  // Absence controllers
  late TextEditingController _sakitController;
  late TextEditingController _izinController;
  late TextEditingController _terlambatController;
  late TextEditingController _mangkirController;
  
  // Signature
  late SignatureController _signatureController;
  Uint8List? _signatureBytes;
  String _signatureMode = 'draw'; // 'draw' or 'upload'
  
  @override
  void initState() {
    super.initState();
    
    // Initialize from existing evaluasi
    _ratings = {};
    _comments = {};
    for (int i = 0; i < _factors.length; i++) {
      _ratings[i] = widget.evaluasi.ratings[i];
      _comments[i] = TextEditingController(text: widget.evaluasi.comments[i] ?? '');
    }
    
    _recommendation = widget.evaluasi.recommendation;
    _perpanjangBulan = widget.evaluasi.perpanjangBulan;
    _notesController = TextEditingController(text: widget.evaluasi.catatan);
    _periodeController = TextEditingController(text: widget.evaluasi.periode);
    
    // Initialize absence controllers
    _sakitController = TextEditingController(text: widget.evaluasi.sakit.toString());
    _izinController = TextEditingController(text: widget.evaluasi.izin.toString());
    _terlambatController = TextEditingController(text: widget.evaluasi.terlambat.toString());
    _mangkirController = TextEditingController(text: widget.evaluasi.mangkir.toString());
    
    // Initialize signature controller
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    
    // Load existing signature if available
    if (widget.evaluasi.signatureBase64 != null && widget.evaluasi.signatureBase64!.isNotEmpty) {
      _signatureBytes = base64Decode(widget.evaluasi.signatureBase64!);
    }
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    _periodeController.dispose();
    _sakitController.dispose();
    _izinController.dispose();
    _terlambatController.dispose();
    _mangkirController.dispose();
    _signatureController.dispose();
    for (var c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }
  
  int get _totalNilai {
    int total = 0;
    for (var r in _ratings.values) {
      if (r != null && r > 0) total += r;
    }
    return total;
  }
  
  int get _totalFaktor {
    int count = 0;
    for (var r in _ratings.values) {
      if (r != null && r > 0) count++;
    }
    return count;
  }
  
  double get _nilaiRataRata {
    if (_totalFaktor == 0) return 0;
    return _totalNilai / _totalFaktor;
  }
  
  String get _status {
    if (_totalFaktor == 0) return '-';
    return _nilaiRataRata >= 3 ? 'LULUS' : 'TIDAK LULUS';
  }
  
  String _convertToGrade(double average) {
    if (average >= 4.5) return 'A';
    if (average >= 4.0) return 'A-';
    if (average >= 3.5) return 'B+';
    if (average >= 3.0) return 'B';
    if (average >= 2.5) return 'C+';
    if (average >= 2.0) return 'C';
    if (average >= 1.5) return 'D';
    return 'E';
  }
  
  void _submit() async {
    // Check if all factors have ratings
    bool allRated = true;
    for (var r in _ratings.values) {
      if (r == null) {
        allRated = false;
        break;
      }
    }
    
    if (!allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Harap lengkapi semua penilaian'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Build catatan from comments
    String fullCatatan = _notesController.text;
    if (fullCatatan.isEmpty) {
      fullCatatan = 'Evaluasi kinerja karyawan periode ${_periodeController.text}';
    }
    
    // Convert ratings to non-nullable map
    Map<int, int> ratingsMap = {};
    for (var entry in _ratings.entries) {
      if (entry.value != null) {
        ratingsMap[entry.key] = entry.value!;
      }
    }
    
    // Convert comments to map
    Map<int, String> commentsMap = {};
    for (var entry in _comments.entries) {
      commentsMap[entry.key] = entry.value.text;
    }
    
    final updatedEvaluasi = widget.evaluasi.copyWith(
      tanggalEvaluasi: DateTime.now(),
      periode: _periodeController.text,
      nilaiKinerja: _convertToGrade(_nilaiRataRata),
      catatan: fullCatatan,
      updatedAt: DateTime.now(),
      ratings: ratingsMap,
      comments: commentsMap,
      recommendation: _recommendation,
      perpanjangBulan: _perpanjangBulan,
      sakit: int.tryParse(_sakitController.text) ?? 0,
      izin: int.tryParse(_izinController.text) ?? 0,
      terlambat: int.tryParse(_terlambatController.text) ?? 0,
      mangkir: int.tryParse(_mangkirController.text) ?? 0,
      signatureBase64: _signatureBytes != null ? base64Encode(_signatureBytes!) : widget.evaluasi.signatureBase64,
    );

    try {
      await Provider.of<EvaluasiProvider>(context, listen: false).updateEvaluasi(widget.evaluasi.id, updatedEvaluasi);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Evaluasi berhasil diperbarui'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Gagal memperbarui: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _exportPdf() async {
    // Check if all factors have ratings
    bool allRated = true;
    for (var r in _ratings.values) {
      if (r == null) {
        allRated = false;
        break;
      }
    }
    
    if (!allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Harap lengkapi semua penilaian sebelum export PDF'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    
    // Show preview dialog instead of direct print
    _showPdfPreview();
  }

  void _showPdfPreview() {
    // Convert comments to Map<int, String>
    Map<int, String> commentsMap = {};
    for (var entry in _comments.entries) {
      commentsMap[entry.key] = entry.value.text;
    }
    
    // Create EvaluasiData
    final evaluasiData = EvaluasiData(
      namaKaryawan: widget.evaluasi.employeeName,
      posisi: widget.evaluasi.employeePosition,
      departemen: widget.evaluasi.employeeDepartemen,
      lokasiKerja: widget.evaluasi.employeeDepartemen,
      atasanLangsung: widget.evaluasi.atasanLangsung,
      tanggalMasuk: widget.evaluasi.tanggalMasuk,
      tanggalPkwtBerakhir: widget.evaluasi.tanggalPkwtBerakhir,
      pkwtKe: widget.evaluasi.pkwtKe,
      tanggalEvaluasi: DateTime.now(),
      sakit: int.tryParse(_sakitController.text) ?? 0,
      izin: int.tryParse(_izinController.text) ?? 0,
      terlambat: int.tryParse(_terlambatController.text) ?? 0,
      mangkir: int.tryParse(_mangkirController.text) ?? 0,
      ratings: _ratings,
      comments: commentsMap,
      recommendation: _recommendation,
      perpanjangBulan: _perpanjangBulan,
      catatan: _notesController.text,
      namaEvaluator: widget.evaluasi.evaluator,
      signatureBase64: _signatureBytes != null ? base64Encode(_signatureBytes!) : widget.evaluasi.signatureBase64,
      hcgsAdminName: widget.evaluasi.hcgsAdminName,
      hcgsSignatureBase64: widget.evaluasi.hcgsSignatureBase64,
    );

    ModernPdfPreviewDialog.show(
      context: context,
      evaluasiData: evaluasiData,
      fileName: 'evaluasi_${widget.evaluasi.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit Evaluasi Karyawan",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Perbarui penilaian kinerja karyawan",
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Employee Info Card
            _buildEmployeeCard(),
            const SizedBox(height: 24),
            
            // Instructions
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            
            // Evaluation Table
            _buildEvaluationTable(),
            const SizedBox(height: 24),
            
            // Summary and Recommendation
            _buildSummaryCard(),
            const SizedBox(height: 24),
            
            // Absence Data
            _buildAbsenceCard(),
            const SizedBox(height: 24),
            
            // Signature
            _buildSignatureCard(),
            const SizedBox(height: 24),
            
            // Notes
            _buildNotesCard(),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: const Text("Preview PDF"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              widget.evaluasi.employeeName.isNotEmpty ? widget.evaluasi.employeeName[0].toUpperCase() : 'K',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.evaluasi.employeeName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.evaluasi.employeePosition} - ${widget.evaluasi.employeeDepartemen}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PKWT Ke-${widget.evaluasi.pkwtKe}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tanggal Evaluasi',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              Text(
                'Periode Evaluasi',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _periodeController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Q1 2025',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 8),
              Text(
                'INSTRUKSI PENILAIAN',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            border: TableBorder.all(color: const Color(0xFFBAE6FD), width: 0.5),
            children: [
              _buildInstructionRow('Nilai', 'Rating', 'Keterangan', isHeader: true),
              _buildInstructionRow('5', 'BS (Baik Sekali)', 'Secara konsisten, mampu bekerja melebihi harapan'),
              _buildInstructionRow('4', 'SB (Sangat Baik)', 'Seringkali bekerja melebihi harapan'),
              _buildInstructionRow('3', 'B (Baik)', 'Secara konsisten, mampu bekerja sesuai harapan'),
              _buildInstructionRow('2', 'K (Kurang)', 'Kadang-kadang bisa bekerja sesuai harapan'),
              _buildInstructionRow('1', 'KS (Kurang Sekali)', 'Tidak mampu bekerja sesuai harapan'),
              _buildInstructionRow('NA', 'Tidak Dinilai', 'Tidak digunakan (tidak dinilai)'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '* Hasil Lulus jika Nilai Rata-rata ≥ 3',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
  
  TableRow _buildInstructionRow(String nilai, String rating, String keterangan, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF0284C7).withOpacity(0.1) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            nilai, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            rating, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            keterangan, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEvaluationTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40, child: Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                const Expanded(flex: 3, child: Text('Faktor yang Dinilai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ...['BS\n(5)', 'SB\n(4)', 'B\n(3)', 'K\n(2)', 'KS\n(1)', 'NA'].map((label) => 
                  SizedBox(
                    width: 40,
                    child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 120, child: Text('Komentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Table Rows
          ...List.generate(_factors.length, (index) => _buildFactorRow(index)),
          // Totals Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(flex: 3, child: Text('TOTAL NILAI PER ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ...List.generate(6, (i) {
                  int val = 5 - i; // 5, 4, 3, 2, 1, 0
                  int count = _ratings.values.where((r) => r == val).length;
                  return SizedBox(
                    width: 40,
                    child: Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                  );
                }),
                const SizedBox(width: 120),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(flex: 3, child: Text('TOTAL SEMUA NILAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Container(
                  width: 240,
                  alignment: Alignment.center,
                  child: Text(_totalNilai.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                ),
                const SizedBox(width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFactorRow(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(_factors[index], style: const TextStyle(fontSize: 12))),
          ...List.generate(6, (i) {
            int val = 5 - i; // 5, 4, 3, 2, 1, 0
            return SizedBox(
              width: 40,
              child: Radio<int>(
                value: val,
                groupValue: _ratings[index],
                onChanged: (v) => setState(() => _ratings[index] = v),
                activeColor: AppColors.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _comments[index],
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Komentar...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HASIL EVALUASI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Total Nilai (TN)', _totalNilai.toString()),
              ),
              Expanded(
                child: _buildSummaryItem('Total Faktor (F)', _totalFaktor.toString()),
              ),
              Expanded(
                child: _buildSummaryItem('Nilai Rata-rata (TN/F)', _nilaiRataRata.toStringAsFixed(2)),
              ),
              Expanded(
                child: _buildSummaryItem('Status', _status),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('REKOMENDASI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<String>(
                value: 'perpanjang',
                groupValue: _recommendation,
                onChanged: (v) => setState(() => _recommendation = v!),
                title: const Text('Perpanjang PKWT', style: TextStyle(fontSize: 14)),
                dense: true,
                activeColor: AppColors.primaryBlue,
              ),
              if (_recommendation == 'perpanjang')
                Padding(
                  padding: const EdgeInsets.only(left: 56, bottom: 8),
                  child: Row(
                    children: [
                      const Text('Lama Perpanjangan: ', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _perpanjangBulan,
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 Bulan')),
                          DropdownMenuItem(value: 6, child: Text('6 Bulan')),
                          DropdownMenuItem(value: 12, child: Text('12 Bulan')),
                        ],
                        onChanged: (v) => setState(() => _perpanjangBulan = v!),
                      ),
                    ],
                  ),
                ),
              RadioListTile<String>(
                value: 'permanen',
                groupValue: _recommendation,
                onChanged: (v) => setState(() => _recommendation = v!),
                title: const Text('Diangkat Permanen', style: TextStyle(fontSize: 14)),
                dense: true,
                activeColor: AppColors.primaryBlue,
              ),
              RadioListTile<String>(
                value: 'berakhir',
                groupValue: _recommendation,
                onChanged: (v) => setState(() => _recommendation = v!),
                title: const Text('PKWT Berakhir', style: TextStyle(fontSize: 14)),
                dense: true,
                activeColor: AppColors.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        ],
      ),
    );
  }
  
  Widget _buildAbsenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DATA KETIDAKHADIRAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAbsenceField('Sakit', _sakitController, Icons.sick_outlined, const Color(0xFFEF4444))),
              const SizedBox(width: 12),
              Expanded(child: _buildAbsenceField('Izin', _izinController, Icons.description_outlined, const Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(child: _buildAbsenceField('Terlambat', _terlambatController, Icons.access_time_outlined, const Color(0xFF8B5CF6))),
              const SizedBox(width: 12),
              Expanded(child: _buildAbsenceField('Mangkir', _mangkirController, Icons.cancel_outlined, const Color(0xFF06B6D4))),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAbsenceField(String label, TextEditingController controller, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: color.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSignatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TANDA TANGAN ATASAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Gambar', style: TextStyle(fontSize: 12)),
                    selected: _signatureMode == 'draw',
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _signatureMode = 'draw';
                          _signatureBytes = null;
                        });
                      }
                    },
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: _signatureMode == 'draw' ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Upload', style: TextStyle(fontSize: 12)),
                    selected: _signatureMode == 'upload',
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _signatureMode = 'upload';
                        });
                        _pickSignatureFile();
                      }
                    },
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: _signatureMode == 'upload' ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_signatureMode == 'draw') ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _signatureController.clear();
                      setState(() => _signatureBytes = null);
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_signatureController.isNotEmpty) {
                        final signature = await _signatureController.toPngBytes();
                        setState(() => _signatureBytes = signature);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tanda tangan disimpan')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_signatureBytes != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_signatureBytes!, fit: BoxFit.contain),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Upload file tanda tangan', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickSignatureFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        setState(() {
          _signatureBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }
  
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CATATAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Tuliskan catatan tambahan...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
