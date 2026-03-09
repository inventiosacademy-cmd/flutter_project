import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/karyawan.dart';
import '../providers/prov_karyawan.dart';
import '../theme/warna.dart';
import '../providers/prov_evaluasi.dart';
import '../providers/prov_pkwt.dart';
import '../models/evaluasi.dart';
import '../services/pdf_generator.dart';
import '../services/pkwt_upload_service.dart';
import '../widgets/pdf_preview_dialog.dart';
import '../providers/prov_evaluation_upload.dart';
import '../services/evaluation_upload_service.dart';

class KontenDetailKaryawan extends StatefulWidget {
  final Employee employee;
  final VoidCallback onBack;

  const KontenDetailKaryawan({
    super.key,
    required this.employee,
    required this.onBack,
  });

  @override
  State<KontenDetailKaryawan> createState() => _KontenDetailKaryawanState();
}

class _KontenDetailKaryawanState extends State<KontenDetailKaryawan> {
  int _selectedTab = 0; // 0 = Personal Profile, 1 = Evaluasi, 2 = PKWT

  // Store provider refs so we can safely call them in dispose()
  PkwtProvider? _pkwtProvider;
  EvaluationUploadProvider? _evalUploadProvider;

  @override
  void initState() {
    super.initState();
    // Initialize PKWT and Evaluation listeners when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pkwtProvider = Provider.of<PkwtProvider>(context, listen: false);
      _evalUploadProvider = Provider.of<EvaluationUploadProvider>(context, listen: false);
      _pkwtProvider!.initPkwtListener(widget.employee.id);
      _evalUploadProvider!.initEvaluationListener(widget.employee.id);
    });
  }

  @override
  void dispose() {
    // Use stored refs — safe to call after widget is deactivated
    _pkwtProvider?.cancelListener(widget.employee.id);
    _evalUploadProvider?.cancelListener(widget.employee.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb / Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          color: Colors.white,
          width: double.infinity,
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: "Kembali",
              ),
              const SizedBox(width: 8),
              const Text(
                "Detail Karyawan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        
        // Main Content Area
        Expanded(
          child: Container(
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel - Profile Card
                Container(
                  width: 340,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.employee.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 28),
                      Consumer<EmployeeProvider>(
                        builder: (context, provider, _) {
                          final index = provider.employees.indexWhere((e) => e.id == widget.employee.id);
                          final displayId = index != -1 
                              ? "EMP-${DateTime.now().year}-${(index + 1).toString().padLeft(3, '0')}"
                              : widget.employee.id;
                          return _buildLeftPanelItem("ID Karyawan", displayId);
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildLeftPanelItem("Masa Kerja", widget.employee.masaKerja),
                    ],
                  ),
                ),
                
                // Right Panel - Tabs & Information
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            children: [
                              _buildTab("Personal Profile", 0),
                              _buildTab("Evaluasi", 1),
                              _buildTab("PKWT", 2),
                            ],
                          ),
                        ),
                        
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(48),
                            child: _selectedTab == 0
                                ? _buildProfileContent()
                                : _selectedTab == 1
                                    ? _buildEvaluasiContent()
                                    : _buildPkwtContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanelItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          border: isActive
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryBlue : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Employment Details - Vertical Layout
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem("Departemen", widget.employee.departemen),
            const SizedBox(height: 24),
            _buildDetailItem("Posisi", widget.employee.posisi),
            const SizedBox(height: 24),
            _buildDetailItem("Atasan Langsung", widget.employee.atasanLangsung),
            const SizedBox(height: 24),
            _buildDetailItem("Tanggal Masuk", DateFormat('dd MMMM yyyy').format(widget.employee.tglMasuk)),
            const SizedBox(height: 24),
            _buildDetailItem("Akhir Kontrak", DateFormat('dd MMMM yyyy').format(widget.employee.tglPkwtBerakhir)),
            const SizedBox(height: 24),
            _buildDetailItem("Status PKWT", "PKWT Ke-${widget.employee.pkwtKe}"),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluasiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assessment_outlined,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Riwayat Evaluasi Karyawan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Unified evaluation table (sistem + manual uploads)
        _buildEvaluationTimeline(),
      ],
    );
  }


  Widget _buildEvaluationTimeline() {
    return Consumer2<EvaluasiProvider, EvaluationUploadProvider>(
      builder: (context, evaluasiProvider, uploadProvider, _) {
        final sistemEvals = evaluasiProvider.getEvaluasiByEmployee(widget.employee.id);
        final uploadEvals = uploadProvider.getEvaluationsByEmployee(widget.employee.id);

        // Build unified rows
        // tipe: 'Sistem' or 'Manual'
        // statusUpload: null (sistem/tidak berlaku), true (sudah upload), false (belum upload)
        final List<Map<String, dynamic>> rows = [];

        for (final eval in sistemEvals) {
          rows.add({
            'date': eval.tanggalEvaluasi,
            'pkwtKe': eval.pkwtKe,
            'tipe': 'Sistem',
            'statusUpload': null, // tidak berlaku untuk sistem
            'eval': eval,
          });
        }

        for (final upload in uploadEvals) {
          rows.add({
            'date': upload.uploadedAt,
            'pkwtKe': upload.pkwtKe,
            'tipe': 'Manual',
            'statusUpload': true, // sudah diupload
            'fileName': upload.fileName,
            'fileUrl': upload.fileUrl,
          });
        }

        // Sort by date descending (newest first)
        rows.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        if (rows.isEmpty) {
          return Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.assessment_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada data evaluasi',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildUploadButton(context),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: const Color(0xFFE2E8F0)),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    DataColumn(label: Text('PKWT Ke-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    DataColumn(label: Text('Status Upload', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  ],
                  rows: rows.map((row) {
                    final isSistem = row['tipe'] == 'Sistem';
                    final statusUpload = row['statusUpload'] as bool?;

                    // Status Upload widget
                    Widget statusUploadWidget;
                    if (isSistem) {
                      statusUploadWidget = Text('-', style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
                    } else if (statusUpload == true) {
                      statusUploadWidget = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Sudah Upload',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                        ),
                      );
                    } else {
                      statusUploadWidget = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Belum Upload',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                        ),
                      );
                    }

                    // Action widget
                    Widget actionWidget;
                    if (isSistem) {
                      final eval = row['eval'] as Evaluasi;
                      actionWidget = IconButton(
                        icon: Icon(Icons.picture_as_pdf, color: AppColors.error),
                        onPressed: () => _showPdfPreview(eval),
                        tooltip: 'Lihat PDF Evaluasi',
                      );
                    } else {
                      // Manual: tombol Lihat + Upload Baru
                      final fileUrl = row['fileUrl'] as String;
                      final fileName = row['fileName'] as String;
                      final pkwtKe = row['pkwtKe'] as int;
                      actionWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.visibility, color: AppColors.primaryBlue),
                            onPressed: () async {
                              try {
                                await EvaluationUploadService().downloadPdf(fileUrl, fileName);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error membuka PDF: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            tooltip: 'Lihat PDF',
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload_file, color: Color(0xFF0EA5E9)),
                            onPressed: () => _showUploadDialog(context, pkwtKe),
                            tooltip: 'Upload Baru',
                          ),
                        ],
                      );
                    }

                    return DataRow(cells: [
                      DataCell(Text(
                        DateFormat('dd MMM yyyy').format(row['date'] as DateTime),
                        style: const TextStyle(color: Color(0xFF334155)),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ke-${row['pkwtKe']}',
                            style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSistem ? const Color(0xFFD1FAE5) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            row['tipe'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSistem ? const Color(0xFF059669) : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ),
                      DataCell(statusUploadWidget),
                      DataCell(actionWidget),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildUploadButton(context),
          ],
        );
      },
    );
  }

  /// Tombol Upload Evaluasi Manual – membuka dialog upload dengan pkwtKe pre-filled
  Widget _buildUploadButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showUploadDialog(context, widget.employee.pkwtKe),
      icon: const Icon(Icons.upload_file, size: 18),
      label: const Text('Upload Evaluasi Manual'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Inline upload dialog dengan pkwtKe sudah terisi
  void _showUploadDialog(BuildContext context, int pkwtKe) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EvalUploadInlineDialog(
        employee: widget.employee,
        pkwtKe: pkwtKe,
      ),
    );
  }

  void _showPdfPreview(Evaluasi evaluasi) {
    // Generate evaluation data
    Map<int, int?> ratingsNullable = {};
    for (var entry in evaluasi.ratings.entries) {
      ratingsNullable[entry.key] = entry.value;
    }

    // Generate EvaluasiData for PDF
    final evaluasiData = EvaluasiData(
      namaKaryawan: evaluasi.employeeName,
      posisi: evaluasi.employeePosition,
      departemen: evaluasi.employeeDepartemen.isNotEmpty ? evaluasi.employeeDepartemen : '-',
      lokasiKerja: evaluasi.employeeDepartemen.isNotEmpty ? evaluasi.employeeDepartemen : '-',
      atasanLangsung: evaluasi.atasanLangsung.isNotEmpty ? evaluasi.atasanLangsung : evaluasi.evaluator,
      tanggalMasuk: evaluasi.tanggalMasuk,
      tanggalPkwtBerakhir: evaluasi.tanggalPkwtBerakhir,
      pkwtKe: evaluasi.pkwtKe,
      tanggalEvaluasi: evaluasi.tanggalEvaluasi,
      ratings: ratingsNullable,
      comments: evaluasi.comments,
      recommendation: evaluasi.recommendation,
      perpanjangBulan: evaluasi.perpanjangBulan,
      catatan: evaluasi.catatan,
      namaEvaluator: evaluasi.evaluator,
      sakit: evaluasi.sakit,
      izin: evaluasi.izin,
      terlambat: evaluasi.terlambat,
      mangkir: evaluasi.mangkir,
      signatureBase64: evaluasi.signatureBase64,
      hcgsAdminName: evaluasi.hcgsAdminName.isNotEmpty ? evaluasi.hcgsAdminName : 'Admin HCGS',
      
      // Fixed 4 Signature Slots
      karyawanSignatureBase64: evaluasi.karyawanSignatureBase64,
      karyawanSignatureNama: evaluasi.karyawanSignatureNama,
      karyawanSignatureJabatan: evaluasi.karyawanSignatureJabatan,
      karyawanSignatureStatus: evaluasi.karyawanSignatureStatus,
      
      atasanSignatureBase64: evaluasi.atasanSignatureBase64,
      atasanSignatureNama: evaluasi.atasanSignatureNama,
      atasanSignatureJabatan: evaluasi.atasanSignatureJabatan,
      atasanSignatureStatus: evaluasi.atasanSignatureStatus,
      
      hcgsSignatureBase64: evaluasi.hcgsSignatureBase64,
      hcgsSignatureNama: evaluasi.hcgsSignatureNama,
      hcgsSignatureJabatan: evaluasi.hcgsSignatureJabatan,
      hcgsSignatureStatus: evaluasi.hcgsSignatureStatus,
      
      fungsionalSignatureBase64: evaluasi.fungsionalSignatureBase64,
      fungsionalSignatureNama: evaluasi.fungsionalSignatureNama,
      fungsionalSignatureJabatan: evaluasi.fungsionalSignatureJabatan,
      fungsionalSignatureStatus: evaluasi.fungsionalSignatureStatus,
    );

    ModernPdfPreviewDialog.show(
      context: context,
      evaluasiData: evaluasiData,
      fileName: 'evaluasi_${evaluasi.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }

  Widget _buildPkwtContent() {
    final uploadService = PkwtUploadService();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Upload Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Dokumen PKWT",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // PKWT Documents List
        Consumer<PkwtProvider>(
          builder: (context, pkwtProvider, _) {
            final documents = pkwtProvider.getPkwtByEmployee(widget.employee.id);

            if (pkwtProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (documents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada dokumen PKWT",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Klik tombol 'Upload PKWT' untuk menambahkan dokumen",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: const Color(0xFFE2E8F0),
                ),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(
                      label: Text('No', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                    DataColumn(
                      label: Text('Nama File', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                    DataColumn(
                      label: Text('PKWT Ke-', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                    DataColumn(
                      label: Text('Tanggal Upload', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                    DataColumn(
                      label: Text('Ukuran', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                    DataColumn(
                      label: Text('Aksi', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                  ],
                  rows: documents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    
                    return DataRow(cells: [
                      DataCell(Text('${index + 1}',
                        style: const TextStyle(color: Color(0xFF334155)))),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            doc.fileName,
                            style: const TextStyle(color: Color(0xFF334155)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${doc.pkwtKe}',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(doc.uploadedAt),
                        style: const TextStyle(color: Color(0xFF334155)))),
                      DataCell(Text(doc.fileSizeFormatted,
                        style: const TextStyle(color: Color(0xFF334155)))),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.visibility, color: AppColors.primaryBlue),
                          onPressed: () async {
                            try {
                              await uploadService.downloadPdf(doc.fileUrl, doc.fileName);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error membuka PDF: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: "Lihat PDF",
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

}

/// Dialog upload evaluasi manual yang digunakan dari tab Riwayat Evaluasi.
/// pkwtKe sudah pre-filled sehingga user tidak perlu mengisi manual.
class _EvalUploadInlineDialog extends StatefulWidget {
  final Employee employee;
  final int pkwtKe;

  const _EvalUploadInlineDialog({
    required this.employee,
    required this.pkwtKe,
  });

  @override
  State<_EvalUploadInlineDialog> createState() => _EvalUploadInlineDialogState();
}

class _EvalUploadInlineDialogState extends State<_EvalUploadInlineDialog> {
  final _uploadService = EvaluationUploadService();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final file = await _uploadService.pickPdfFile();
      if (file != null && mounted) setState(() => _selectedFile = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file PDF terlebih dahulu'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final evaluationUpload = await _uploadService.uploadEvaluationPdf(
        employeeId: widget.employee.id,
        pdfFile: _selectedFile!,
        pkwtKe: widget.pkwtKe,
      );
      if (mounted) {
        await Provider.of<EvaluationUploadProvider>(context, listen: false)
            .addEvaluationUpload(evaluationUpload);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluasi manual berhasil disimpan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.upload_file, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Evaluasi Manual',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        '${widget.employee.nama} · PKWT Ke-${widget.pkwtKe}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (!_isUploading)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // File picker
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null ? AppColors.primaryBlue : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null
                      ? AppColors.primaryBlue.withOpacity(0.04)
                      : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                      size: 48,
                      color: _selectedFile != null ? AppColors.primaryBlue : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null ? _selectedFile!.name : 'Klik untuk pilih file PDF evaluasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedFile != null ? AppColors.primaryBlue : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Mengupload...', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isUploading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadFile,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isUploading ? 'Menyimpan...' : 'Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
