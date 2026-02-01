import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import '../models/karyawan.dart';
import '../models/evaluasi.dart';
import '../providers/prov_karyawan.dart';
import '../providers/prov_evaluasi.dart';
import '../theme/warna.dart';
import '../services/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../widgets/pdf_preview_dialog.dart';
import 'package:signature/signature.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class KontenEvaluasi extends StatefulWidget {
  final Employee employee;
  final VoidCallback onBack;
  
  const KontenEvaluasi({super.key, required this.employee, required this.onBack});

  @override
  State<KontenEvaluasi> createState() => _KontenEvaluasiState();
}

class _KontenEvaluasiState extends State<KontenEvaluasi> {
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
  String _recommendation = 'perpanjang';
  int _perpanjangBulan = 6;
  final _notesController = TextEditingController();
  final _periodeController = TextEditingController();
  
  // Absence controllers
  final _sakitController = TextEditingController();
  final _izinController = TextEditingController();
  final _terlambatController = TextEditingController();
  final _mangkirController = TextEditingController();
  
  // Multiple Signatures
  final List<_SignatureData> _signatures = [];
  
  @override
  void initState() {
    super.initState();
    _ratings = {};
    _comments = {};
    for (int i = 0; i < _factors.length; i++) {
      _ratings[i] = null;
      _comments[i] = TextEditingController();
    }
    // Set default periode
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    _periodeController.text = 'Q$quarter ${now.year}';
    
    // Initialize absence controllers with default value "0"
    _sakitController.text = '0';
    _izinController.text = '0';
    _terlambatController.text = '0';
    _mangkirController.text = '0';
    
    // Initialize with one default signature for Atasan Langsung
    _addSignature(defaultName: 'Atasan Langsung');
  }
  
  void _addSignature({String? defaultName}) {
    final newController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    
    // Auto-save listener: save signature 500ms after user stops drawing
    Timer? autoSaveTimer;
    newController.addListener(() {
      autoSaveTimer?.cancel();
      autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
        if (newController.isNotEmpty) {
          final bytes = await newController.toPngBytes();
          final index = _signatures.indexWhere((s) => s.signatureController == newController);
          if (index != -1 && mounted) {
            setState(() {
              _signatures[index].signatureBytes = bytes;
            });
            print('✓ Auto-saved signature for ${_signatures[index].role}: ${_signatures[index].nameController.text}');
          }
        }
      });
    });
    
    setState(() {
      _signatures.add(_SignatureData(
        nameController: TextEditingController(text: defaultName ?? 'Penanda Tangan ${_signatures.length + 1}'),
        signatureController: newController,
      ));
    });
  }
  
  void _removeSignature(int index) {
    if (_signatures.length > 1 && index > 0) {  // Keep at least one, can't remove first
      setState(() {
        _signatures[index].nameController.dispose();
        _signatures[index].signatureController.dispose();
        _signatures.removeAt(index);
      });
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
    // Dispose all signatures
    for (var sig in _signatures) {
      sig.nameController.dispose();
      sig.signatureController.dispose();
    }
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
    
    final evaluasi = Evaluasi(
      id: const Uuid().v4(),
      employeeId: widget.employee.id,
      employeeName: widget.employee.nama,
      employeePosition: widget.employee.posisi,
      employeeDepartemen: widget.employee.departemen,
      atasanLangsung: widget.employee.atasanLangsung,
      tanggalMasuk: widget.employee.tglMasuk,
      tanggalPkwtBerakhir: widget.employee.tglPkwtBerakhir,
      pkwtKe: widget.employee.pkwtKe,
      tanggalEvaluasi: DateTime.now(),
      periode: _periodeController.text,
      nilaiKinerja: _convertToGrade(_nilaiRataRata),
      catatan: fullCatatan,
      status: EvaluasiStatus.belumTTD,
      evaluator: 'HR Manager', // TODO: Get from auth
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      ratings: ratingsMap,
      comments: commentsMap,
      recommendation: _recommendation,
      perpanjangBulan: _perpanjangBulan,
      sakit: int.tryParse(_sakitController.text) ?? 0,
      izin: int.tryParse(_izinController.text) ?? 0,
      terlambat: int.tryParse(_terlambatController.text) ?? 0,
      mangkir: int.tryParse(_mangkirController.text) ?? 0,
      
      // Collect signatures by role
      atasanSignatureBase64: _getSignatureByRole('Atasan'),
      atasanSignatureNama: _getSignatureNameByRole('Atasan'),
      karyawanSignatureBase64: _getSignatureByRole('Karyawan'),
      karyawanSignatureNama: _getSignatureNameByRole('Karyawan'),
      hcgsSignatureBase64: _getSignatureByRole('HCGS'),
      hcgsSignatureNama: _getSignatureNameByRole('HCGS'),
      fungsionalSignatureBase64: _getSignatureByRole('Fungsional'),
      fungsionalSignatureNama: _getSignatureNameByRole('Fungsional'),
      
      // Legacy field - use first signature for backward compatibility
      signatureBase64: _signatures.isNotEmpty && _signatures[0].signatureBytes != null 
          ? base64Encode(_signatures[0].signatureBytes!) 
          : null,
      hcgsAdminName: _getSignatureNameByRole('HCGS') ?? 'Admin HCGS',
    );

    try {
      await Provider.of<EvaluasiProvider>(context, listen: false).addEvaluasi(evaluasi);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Evaluasi berhasil disimpan ke Firestore'),
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
                Expanded(child: Text('Gagal menyimpan: $e')),
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
  
  // Helper methods to get signature by role
  String? _getSignatureByRole(String role) {
    print('=== Getting signature for role: $role ===');
    print('Total signatures: ${_signatures.length}');
    for (var i = 0; i < _signatures.length; i++) {
      var sig = _signatures[i];
      print('Signature $i: role=${sig.role}, hasBytes=${sig.signatureBytes != null}, bytesLength=${sig.signatureBytes?.length}');
      if (sig.role == role && sig.signatureBytes != null) {
        print('✓ Found match for role $role at index $i');
        return base64Encode(sig.signatureBytes!);
      }
    }
    print('✗ No signature found for role $role');
    return null;
  }
  
  String? _getSignatureNameByRole(String role) {
    for (var sig in _signatures) {
      if (sig.role == role && sig.nameController.text.isNotEmpty) {
        return sig.nameController.text;
      }
    }
    return null;
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
    print('>>> _showPdfPreview() CALLED <<<');
    
    // Convert comments to Map<int, String>
    Map<int, String> commentsMap = {};
    for (var entry in _comments.entries) {
      commentsMap[entry.key] = entry.value.text;
    }
    
    // Create EvaluasiData
    final evaluasiData = EvaluasiData.fromEmployee(
      widget.employee,
      ratings: _ratings,
      comments: commentsMap,
      recommendation: _recommendation,
      perpanjangBulan: _perpanjangBulan,
      catatan: _notesController.text,
      namaEvaluator: 'HR Manager', // TODO: Get from auth
      sakit: int.tryParse(_sakitController.text) ?? 0,
      izin: int.tryParse(_izinController.text) ?? 0,
      terlambat: int.tryParse(_terlambatController.text) ?? 0,
      mangkir: int.tryParse(_mangkirController.text) ?? 0,
    );
    
    // Debug: Check what helper methods return
    print('=== Creating PDF Data ===');
    final atasanSig = _getSignatureByRole('Atasan');
    final atasanName = _getSignatureNameByRole('Atasan');
    final karyawanSig = _getSignatureByRole('Karyawan');
    final karyawanName = _getSignatureNameByRole('Karyawan');
    final hcgsSig = _getSignatureByRole('HCGS');
    final hcgsName = _getSignatureNameByRole('HCGS');
    final fungsionalSig = _getSignatureByRole('Fungsional');
    final fungsionalName = _getSignatureNameByRole('Fungsional');
    
    print('Atasan: sig=${atasanSig?.substring(0, 20)}..., name=$atasanName');
    print('Karyawan: sig=${karyawanSig?.substring(0, 20)}..., name=$karyawanName');
    print('HCGS: sig=${hcgsSig?.substring(0, 20)}..., name=$hcgsName');
    print('Fungsional: sig=${fungsionalSig?.substring(0, 20)}..., name=$fungsionalName');
    
    // Create a new EvaluasiData with signature
    final evaluasiDataWithSignature = EvaluasiData(
      namaKaryawan: evaluasiData.namaKaryawan,
      posisi: evaluasiData.posisi,
      departemen: evaluasiData.departemen,
      lokasiKerja: evaluasiData.lokasiKerja,
      atasanLangsung: evaluasiData.atasanLangsung,
      tanggalMasuk: evaluasiData.tanggalMasuk,
      tanggalPkwtBerakhir: evaluasiData.tanggalPkwtBerakhir,
      pkwtKe: evaluasiData.pkwtKe,
      tanggalEvaluasi: evaluasiData.tanggalEvaluasi,
      sakit: evaluasiData.sakit,
      izin: evaluasiData.izin,
      terlambat: evaluasiData.terlambat,
      mangkir: evaluasiData.mangkir,
      ratings: evaluasiData.ratings,
      comments: evaluasiData.comments,
      recommendation: evaluasiData.recommendation,
      perpanjangBulan: evaluasiData.perpanjangBulan,
      catatan: evaluasiData.catatan,
      namaEvaluator: evaluasiData.namaEvaluator,
      
      // Role-based signatures for PDF
      atasanSignatureBase64: atasanSig,
      atasanSignatureNama: atasanName,
      karyawanSignatureBase64: karyawanSig,
      karyawanSignatureNama: karyawanName,
      hcgsSignatureBase64: hcgsSig,
      hcgsSignatureNama: hcgsName,
      fungsionalSignatureBase64: fungsionalSig,
      fungsionalSignatureNama: fungsionalName,
      
      // Legacy fields
      signatureBase64: _signatures.isNotEmpty && _signatures[0].signatureBytes != null 
          ? base64Encode(_signatures[0].signatureBytes!) 
          : null,
      hcgsAdminName: hcgsName ?? 'Admin HCGS',
    );

    ModernPdfPreviewDialog.show(
      context: context,
      evaluasiData: evaluasiDataWithSignature,
      fileName: 'evaluasi_${widget.employee.nama.replaceAll(' ', '_')}.pdf',
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
                      "Form Evaluasi Karyawan",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Lakukan penilaian kinerja karyawan",
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
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
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
                          Text("Simpan Evaluasi", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
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
              widget.employee.nama.isNotEmpty ? widget.employee.nama[0].toUpperCase() : 'K',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.nama,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.employee.posisi} - ${widget.employee.departemen}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masa Kerja: ${widget.employee.masaKerja}',
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
                child: _buildSummaryItem('Nilai Rata-rata (R)', _nilaiRataRata.toStringAsFixed(2)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _status == 'LULUS' ? const Color(0xFFD1FAE5) : _status == '-' ? Colors.grey.shade100 : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text(
                        _status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _status == 'LULUS' ? const Color(0xFF22C55E) : _status == '-' ? Colors.grey : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('REKOMENDASI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('Perpanjang Kontrak', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '6',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          onChanged: (v) => _perpanjangBulan = int.tryParse(v) ?? 6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Bulan', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  value: 'perpanjang',
                  groupValue: _recommendation,
                  onChanged: (v) => setState(() => _recommendation = v!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Permanen', style: TextStyle(fontSize: 13)),
                  value: 'permanen',
                  groupValue: _recommendation,
                  onChanged: (v) => setState(() => _recommendation = v!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Kontrak Berakhir', style: TextStyle(fontSize: 13)),
                  value: 'berakhir',
                  groupValue: _recommendation,
                  onChanged: (v) => setState(() => _recommendation = v!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
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
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
          const Text('KETIDAKHADIRAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('Data ketidakhadiran selama masa penilaian PKWT', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAbsenceField(
                  'Sakit',
                  _sakitController,
                  Icons.medical_services_rounded,
                  const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAbsenceField(
                  'Izin',
                  _izinController,
                  Icons.event_available_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAbsenceField(
                  'Terlambat',
                  _terlambatController,
                  Icons.schedule_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAbsenceField(
                  'Mangkir',
                  _mangkirController,
                  Icons.person_off_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAbsenceField(String label, TextEditingController controller, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'hari',
              suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ],
      ),
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
          const Text('TANDA TANGAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          
          // Loop through all signatures
          ...List.generate(_signatures.length, (index) {
            final sig = _signatures[index];
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 20),
                if (index > 0) Divider(color: Colors.grey.shade200, thickness: 1),
                if (index > 0) const SizedBox(height: 20),
                
                _buildSingleSignature(sig, index),
              ],
            );
          }),
          
          // Add button
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addSignature(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah Tanda Tangan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSingleSignature(_SignatureData sig, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field and controls row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: sig.nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Penanda Tangan',
                  hintText: 'Contoh: Budi Santoso',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Role dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                value: sig.role,
                decoration: InputDecoration(
                  labelText: 'Jabatan',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'Atasan', child: Text('Atasan')),
                  DropdownMenuItem(value: 'Karyawan', child: Text('Karyawan')),
                  DropdownMenuItem(value: 'HCGS', child: Text('HCGS')),
                  DropdownMenuItem(value: 'Fungsional', child: Text('Fungsional')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => sig.role = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            // Mode toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        sig.mode = 'draw';
                        sig.signatureBytes = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sig.mode == 'draw' ? AppColors.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.draw_rounded, 
                            size: 16, 
                            color: sig.mode == 'draw' ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Gambar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sig.mode == 'draw' ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        sig.mode = 'upload';
                        sig.signatureController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sig.mode == 'upload' ? AppColors.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file_rounded, 
                            size: 16, 
                            color: sig.mode == 'upload' ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Upload',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sig.mode == 'upload' ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Remove button (except first one)
            if (index > 0) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeSignature(index),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'Hapus Tanda Tangan',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // Signature area
        if (sig.mode == 'draw') ...[
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Signature(
                controller: sig.signatureController,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    sig.signatureController.clear();
                    setState(() => sig.signatureBytes = null);
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: sig.signatureBytes != null ? AppColors.success.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sig.signatureBytes != null ? AppColors.success : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sig.signatureBytes != null ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: sig.signatureBytes != null ? AppColors.success : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sig.signatureBytes != null ? 'Tersimpan' : 'Menunggu...',
                        style: TextStyle(
                          color: sig.signatureBytes != null ? AppColors.success : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Upload mode
          InkWell(
            onTap: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png'],
                  withData: true,
                );
                
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  Uint8List? bytes;
                  if (file.bytes != null) {
                    bytes = file.bytes;
                  } else if (file.path != null) {
                    bytes = await File(file.path!).readAsBytes();
                  }
                  
                  if (bytes != null) {
                    setState(() => sig.signatureBytes = bytes);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Gambar berhasil diupload'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Gagal upload: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            },
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: sig.signatureBytes == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Klik untuk upload',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(sig.signatureBytes!, fit: BoxFit.contain),
                    ),
            ),
          ),
          if (sig.signatureBytes != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => sig.signatureBytes = null),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Hapus Gambar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
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
          const Text('CATATAN TAMBAHAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan evaluasi...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to hold signature data
class _SignatureData {
  final TextEditingController nameController;
  final SignatureController signatureController;
  Uint8List? signatureBytes;
  String mode; // 'draw' or 'upload'
  String role; // 'Atasan', 'Karyawan', 'HCGS', 'Fungsional'
  
  _SignatureData({
    required this.nameController,
    required this.signatureController,
    this.signatureBytes,
    this.mode = 'draw',
    this.role = 'Atasan',
  });
}
