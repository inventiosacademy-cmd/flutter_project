import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:signature/signature.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/evaluasi.dart';
import '../providers/prov_evaluasi.dart';
import '../theme/warna.dart';
import '../widgets/pdf_preview_dialog.dart';
import '../services/pdf_generator.dart';

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
  late TextEditingController _perpanjangController;
  
  // Absence controllers
  late TextEditingController _sakitController;
  late TextEditingController _izinController;
  late TextEditingController _terlambatController;
  late TextEditingController _mangkirController;
  
  // Multiple Signatures
  final List<_SignatureData> _signatures = [];
  
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
    _perpanjangController = TextEditingController(text: widget.evaluasi.perpanjangBulan.toString());
    
    // Initialize absence controllers
    _sakitController = TextEditingController(text: widget.evaluasi.sakit.toString());
    _izinController = TextEditingController(text: widget.evaluasi.izin.toString());
    _terlambatController = TextEditingController(text: widget.evaluasi.terlambat.toString());
    _mangkirController = TextEditingController(text: widget.evaluasi.mangkir.toString());
    
    // Initialize 4 fixed signatures
    _initFixedSignatures();
  }

  void _initFixedSignatures() {
    _signatures.clear();
    
    // 1. Karyawan (Yang Dinilai)
    _addFixedSignature(
      role: 'Karyawan',
      defaultJabatan: 'Yang Dinilai',
      existingName: widget.evaluasi.karyawanSignatureNama ?? widget.evaluasi.employeeName,
      existingJabatan: widget.evaluasi.karyawanSignatureJabatan,
      existingBase64: widget.evaluasi.karyawanSignatureBase64,
      existingStatus: widget.evaluasi.karyawanSignatureStatus ?? 'Diketahui',
    );
    
    // 2. Atasan (Atasan Langsung)
    // Legacy support: if signatureBase64 exists but atasanSignatureBase64 is null, use legacy as Atasan
    String? effectiveAtasanBase64 = widget.evaluasi.atasanSignatureBase64;
    if (effectiveAtasanBase64 == null && widget.evaluasi.signatureBase64 != null && widget.evaluasi.signatureBase64!.isNotEmpty) {
      effectiveAtasanBase64 = widget.evaluasi.signatureBase64;
    }
    
    _addFixedSignature(
      role: 'Atasan',
      defaultJabatan: 'Atasan Langsung',
      existingName: widget.evaluasi.atasanSignatureNama ?? widget.evaluasi.evaluator,
      existingJabatan: widget.evaluasi.atasanSignatureJabatan,
      existingBase64: effectiveAtasanBase64,
      existingStatus: widget.evaluasi.atasanSignatureStatus ?? 'Diketahui',
    );
    
    // 3. HCGS
    _addFixedSignature(
      role: 'HCGS',
      defaultJabatan: 'HCGS',
      existingName: widget.evaluasi.hcgsSignatureNama ?? widget.evaluasi.hcgsAdminName ?? 'Admin HCGS',
      existingJabatan: widget.evaluasi.hcgsSignatureJabatan,
      existingBase64: widget.evaluasi.hcgsSignatureBase64,
      existingStatus: widget.evaluasi.hcgsSignatureStatus ?? 'Diketahui',
    );
    
    // 4. Fungsional
    _addFixedSignature(
      role: 'Fungsional',
      defaultJabatan: 'Fungsional',
      existingName: widget.evaluasi.fungsionalSignatureNama ?? '',
      existingJabatan: widget.evaluasi.fungsionalSignatureJabatan,
      existingBase64: widget.evaluasi.fungsionalSignatureBase64,
      existingStatus: widget.evaluasi.fungsionalSignatureStatus ?? 'Diketahui',
    );
  }

  void _addFixedSignature({
    required String role, 
    required String defaultJabatan,
    String existingName = '',
    String? existingJabatan,
    String? existingBase64,
    String existingStatus = 'Diketahui',
  }) {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    
    // Auto-save listener
    Timer? autoSaveTimer;
    controller.addListener(() {
      autoSaveTimer?.cancel();
      autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
        if (controller.isNotEmpty) {
          final bytes = await controller.toPngBytes();
          final index = _signatures.indexWhere((s) => s.signatureController == controller);
          if (index != -1 && mounted) {
            setState(() {
              _signatures[index].signatureBytes = bytes;
            });
          }
        }
      });
    });
    
    // Decode existing signature if available
    Uint8List? initialBytes;
    if (existingBase64 != null && existingBase64.isNotEmpty) {
      try {
        initialBytes = base64Decode(existingBase64);
      } catch (e) {
        print('Error decoding signature for $role: $e');
      }
    }
    
    _signatures.add(_SignatureData(
      nameController: TextEditingController(text: existingName),
      jabatanController: TextEditingController(text: existingJabatan ?? defaultJabatan),
      signatureController: controller,
      role: role,
      status: existingStatus,
      signatureBytes: initialBytes,
      mode: initialBytes != null ? 'upload' : 'draw', // If has data, show as upload/image by default
    ));
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    _periodeController.dispose();
    _sakitController.dispose();
    _izinController.dispose();
    _terlambatController.dispose();
    _mangkirController.dispose();
    
    for (var sig in _signatures) {
      sig.nameController.dispose();
      sig.jabatanController.dispose();
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
  
  Future<void> _captureSignatures() async {
    print('DEBUG: Starting _captureSignatures');
    for (int i = 0; i < _signatures.length; i++) {
      final sig = _signatures[i];
      print('DEBUG: Sig $i [${sig.role}] - Mode: ${sig.mode}, Points: ${sig.signatureController.points.length}, HasBytes: ${sig.signatureBytes != null}');
      
      if (sig.mode == 'draw' && sig.signatureController.isNotEmpty) {
        try {
          final bytes = await sig.signatureController.toPngBytes();
          if (bytes != null) {
            sig.signatureBytes = bytes;
            print('DEBUG: Captured new bytes for ${sig.role}: ${bytes.length} bytes');
          } else {
            print('DEBUG: Failed to capture bytes for ${sig.role} (returned null)');
          }
        } catch (e) {
          print('DEBUG: Error capturing signature for ${sig.role}: $e');
        }
      } else if (sig.mode == 'draw' && sig.signatureController.isEmpty) {
         // Optionally clear bytes if in draw mode and pad is empty? 
         // For now, let's just log it.
         print('DEBUG: Sig $i is in draw mode but controller is empty. Keeping existing bytes: ${sig.signatureBytes?.length}');
      }
    }
    if (mounted) setState(() {});
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
    
    // Ensure signatures are captured
    await _captureSignatures();
    
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
    
    // Prepare signature data from fixed slots
    // 0: Karyawan, 1: Atasan, 2: HCGS, 3: Fungsional
    String? karyawanSig = _signatures.isNotEmpty && _signatures[0].signatureBytes != null ? base64Encode(_signatures[0].signatureBytes!) : null;
    String? karyawanName = _signatures.isNotEmpty ? _signatures[0].nameController.text : null;
    String? karyawanJabatan = _signatures.isNotEmpty ? _signatures[0].jabatanController.text : null;
    String? karyawanStatus = _signatures.isNotEmpty ? _signatures[0].status : null;
    
    String? atasanSig = _signatures.length > 1 && _signatures[1].signatureBytes != null ? base64Encode(_signatures[1].signatureBytes!) : null;
    String? atasanName = _signatures.length > 1 ? _signatures[1].nameController.text : null;
    String? atasanJabatan = _signatures.length > 1 ? _signatures[1].jabatanController.text : null;
    String? atasanStatus = _signatures.length > 1 ? _signatures[1].status : null;
    
    String? hcgsSig = _signatures.length > 2 && _signatures[2].signatureBytes != null ? base64Encode(_signatures[2].signatureBytes!) : null;
    String? hcgsName = _signatures.length > 2 ? _signatures[2].nameController.text : null;
    String? hcgsJabatan = _signatures.length > 2 ? _signatures[2].jabatanController.text : null;
    String? hcgsStatus = _signatures.length > 2 ? _signatures[2].status : null;
    
    String? fungsionalSig = _signatures.length > 3 && _signatures[3].signatureBytes != null ? base64Encode(_signatures[3].signatureBytes!) : null;
    String? fungsionalName = _signatures.length > 3 ? _signatures[3].nameController.text : null;
    String? fungsionalJabatan = _signatures.length > 3 ? _signatures[3].jabatanController.text : null;
    String? fungsionalStatus = _signatures.length > 3 ? _signatures[3].status : null;
    
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
      
      // Update Signatures - Directly map 4 fixed slots
      karyawanSignatureBase64: karyawanSig,
      karyawanSignatureNama: karyawanName,
      karyawanSignatureJabatan: karyawanJabatan,
      karyawanSignatureStatus: karyawanStatus,
      
      atasanSignatureBase64: atasanSig,
      atasanSignatureNama: atasanName,
      atasanSignatureJabatan: atasanJabatan,
      atasanSignatureStatus: atasanStatus,
      
      hcgsSignatureBase64: hcgsSig,
      hcgsSignatureNama: hcgsName,
      hcgsSignatureJabatan: hcgsJabatan,
      hcgsSignatureStatus: hcgsStatus,
      
      fungsionalSignatureBase64: fungsionalSig,
      fungsionalSignatureNama: fungsionalName,
      fungsionalSignatureJabatan: fungsionalJabatan,
      fungsionalSignatureStatus: fungsionalStatus,
      
      // Legacy fields
      signatureBase64: karyawanSig, // Legacy primarily used evaluator signature, now standardized
      hcgsAdminName: hcgsName ?? widget.evaluasi.hcgsAdminName,
      evaluator: atasanName ?? widget.evaluasi.evaluator,
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
    
    // Ensure signatures are captured
    await _captureSignatures();
    
    // Show preview dialog instead of direct print
    _showPdfPreview();
  }

  void _showPdfPreview() {
    // Convert comments to Map<int, String>
    Map<int, String> commentsMap = {};
    for (var entry in _comments.entries) {
      commentsMap[entry.key] = entry.value.text;
    }
    
    // Get signatures by index (up to 4)
    String? sig1 = _signatures.isNotEmpty && _signatures[0].signatureBytes != null ? base64Encode(_signatures[0].signatureBytes!) : null;
    String? name1 = _signatures.isNotEmpty ? _signatures[0].nameController.text : null;
    String? jab1 = _signatures.isNotEmpty ? _signatures[0].jabatanController.text : null;
    
    String? sig2 = _signatures.length > 1 && _signatures[1].signatureBytes != null ? base64Encode(_signatures[1].signatureBytes!) : null;
    String? name2 = _signatures.length > 1 ? _signatures[1].nameController.text : null;
    String? jab2 = _signatures.length > 1 ? _signatures[1].jabatanController.text : null;
    
    String? sig3 = _signatures.length > 2 && _signatures[2].signatureBytes != null ? base64Encode(_signatures[2].signatureBytes!) : null;
    String? name3 = _signatures.length > 2 ? _signatures[2].nameController.text : null;
    String? jab3 = _signatures.length > 2 ? _signatures[2].jabatanController.text : null;
    
    String? sig4 = _signatures.length > 3 && _signatures[3].signatureBytes != null ? base64Encode(_signatures[3].signatureBytes!) : null;
    String? name4 = _signatures.length > 3 ? _signatures[3].nameController.text : null;
    String? jab4 = _signatures.length > 3 ? _signatures[3].jabatanController.text : null;
    
    print('DEBUG: PDF Preview Data:');
    print('  Sig 1 (Karyawan): ${sig1 != null}');
    print('  Sig 2 (Atasan): ${sig2 != null}');
    print('  Sig 3 (HCGS): ${sig3 != null}');
    print('  Sig 4 (Fungsional): ${sig4 != null}');
    
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
      
      // Map signatures for PDF
      karyawanSignatureBase64: sig1,
      karyawanSignatureNama: name1,
      karyawanSignatureJabatan: jab1,
      karyawanSignatureStatus: _signatures.isNotEmpty ? _signatures[0].status : null,
      
      atasanSignatureBase64: sig2,
      atasanSignatureNama: name2,
      atasanSignatureJabatan: jab2,
      atasanSignatureStatus: _signatures.length > 1 ? _signatures[1].status : null,
      
      hcgsSignatureBase64: sig3,
      hcgsSignatureNama: name3,
      hcgsSignatureJabatan: jab3,
      hcgsSignatureStatus: _signatures.length > 2 ? _signatures[2].status : null,
      
      fungsionalSignatureBase64: sig4,
      fungsionalSignatureNama: name4,
      fungsionalSignatureJabatan: jab4,
      fungsionalSignatureStatus: _signatures.length > 3 ? _signatures[3].status : null,
      
      // Legacy
      signatureBase64: sig1,
      hcgsAdminName: name3 ?? 'Admin HCGS',
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
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
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
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w400,
              color: const Color(0xFF1E293B),
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
                            hintText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          controller: _perpanjangController,
                          onChanged: (v) => _perpanjangBulan = int.tryParse(v) ?? 0,
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
              Expanded(child: _buildAbsenceField('Sakit', _sakitController)),
              const SizedBox(width: 16),
              Expanded(child: _buildAbsenceField('Izin', _izinController)),
              const SizedBox(width: 16),
              Expanded(child: _buildAbsenceField('Terlambat', _terlambatController)),
              const SizedBox(width: 16),
              Expanded(child: _buildAbsenceField('Mangkir', _mangkirController)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAbsenceField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: 'hari',
            suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
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
          const Text('TANDA TANGAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          
          // Fixed 4 Signature Slots
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _signatures.length,
            separatorBuilder: (context, index) => const Divider(height: 32, thickness: 1),
            itemBuilder: (context, index) {
              return _buildSingleSignature(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSignature(int index) {
    if (index >= _signatures.length) return const SizedBox();
    final sig = _signatures[index];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with modes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tanda Tangan ${index + 1}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))
            ),
            Row(
              children: [
                // Draw Mode
                InkWell(
                  onTap: () => setState(() => sig.mode = 'draw'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sig.mode == 'draw' ? AppColors.primaryBlue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.draw_rounded, size: 16, color: sig.mode == 'draw' ? Colors.white : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Gambar', style: TextStyle(fontSize: 12, color: sig.mode == 'draw' ? Colors.white : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Upload Mode
                InkWell(
                  onTap: () => setState(() => sig.mode = 'upload'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sig.mode == 'upload' ? AppColors.primaryBlue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.upload_rounded, size: 16, color: sig.mode == 'upload' ? Colors.white : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Upload', style: TextStyle(fontSize: 12, color: sig.mode == 'upload' ? Colors.white : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Name, Jabatan, Status fields
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Penanda Tangan', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sig.nameController,
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jabatan', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sig.jabatanController,
                    decoration: InputDecoration(
                      hintText: 'Jabatan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Status field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: sig.status,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Diketahui', child: Text('Diketahui')),
                      DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => sig.status = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Signature area
        if (sig.mode == 'draw') ...[
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Signature(
                controller: sig.signatureController,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Clear button
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                sig.signatureController.clear();
                setState(() => sig.signatureBytes = null);
              },
              icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.grey.shade600),
              label: Text('Bersihkan', style: TextStyle(color: Colors.grey.shade600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ),
          ),
        ] else ...[
          // Upload mode contents (unchanged logic)
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
                  }
                }
              } catch (e) {
                // error handling
              }
            },
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: sig.signatureBytes == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Klik untuk upload gambar',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => sig.signatureBytes = null),
                icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.grey.shade600),
                label: Text('Ganti Gambar', style: TextStyle(color: Colors.grey.shade600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
  final TextEditingController jabatanController;
  final SignatureController signatureController;
  Uint8List? signatureBytes;
  String mode; // 'draw' or 'upload'
  String role; // 'Atasan', 'Karyawan', 'HCGS', 'Fungsional'
  String status; // 'Diketahui' or 'Disetujui'
  
  _SignatureData({
    required this.nameController,
    required this.jabatanController,
    required this.signatureController,
    this.signatureBytes,
    this.mode = 'draw',
    this.role = 'Atasan',
    this.status = 'Diketahui',
  });
}
