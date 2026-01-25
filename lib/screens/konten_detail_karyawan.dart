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
import 'package:printing/printing.dart';
import '../widgets/pdf_preview_dialog.dart';
import '../widgets/pkwt_upload_dialog.dart';
import '../widgets/evaluation_upload_dialog.dart';
import '../providers/prov_evaluation_upload.dart';
import '../models/evaluation_upload.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize PKWT and Evaluation listeners when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PkwtProvider>(context, listen: false)
          .initPkwtListener(widget.employee.id);
      Provider.of<EvaluationUploadProvider>(context, listen: false)
          .initEvaluationListener(widget.employee.id);
    });
  }

  @override
  void dispose() {
    // Cancel PKWT and Evaluation listeners when leaving page
    Provider.of<PkwtProvider>(context, listen: false)
        .cancelListener(widget.employee.id);
    Provider.of<EvaluationUploadProvider>(context, listen: false)
        .cancelListener(widget.employee.id);
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
            ElevatedButton.icon(
              onPressed: () {
                EvaluationUploadDialog.show(context, widget.employee.id);
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text("Upload Evaluasi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Timeline design for evaluations
        _buildEvaluationTimeline(),
        
        const SizedBox(height: 32),
        
        // Uploaded Evaluations Section
        _buildUploadedEvaluationsSection(),
      ],
    );
  }

  Widget _buildEvaluationTimeline() {
    return Consumer<EvaluasiProvider>(
      builder: (context, provider, _) {
        final evaluations = provider.getEvaluasiByEmployee(widget.employee.id);

        if (evaluations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada data evaluasi",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
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
                  label: Text('Tanggal Evaluasi', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))
                ),
                DataColumn(
                  label: Text('PKWT Ke-', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))
                ),
                DataColumn(
                  label: Text('Laporan PDF', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))
                ),
              ],
              rows: evaluations.map((eval) {
                return DataRow(cells: [
                  DataCell(Text(DateFormat('dd MMMM yyyy').format(eval.tanggalEvaluasi),
                    style: const TextStyle(color: Color(0xFF334155)))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ke-${eval.pkwtKe}',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf, color: AppColors.error),
                      onPressed: () => _showPdfPreview(eval),
                      tooltip: "Lihat PDF",
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        );
      },
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
      hcgsSignatureBase64: evaluasi.hcgsSignatureBase64,
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
            ElevatedButton.icon(
              onPressed: () {
                PkwtUploadDialog.show(context, widget.employee.id);
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text("Upload PKWT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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

  Widget _buildUploadedEvaluationsSection() {
    final uploadService = EvaluationUploadService();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 20,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Dokumen Evaluasi Terupload",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Uploaded Evaluations Table
        Consumer<EvaluationUploadProvider>(
          builder: (context, evalProvider, _) {
            final uploads = evalProvider.getEvaluationsByEmployee(widget.employee.id);

            if (evalProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (uploads.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada evaluasi terupload",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Klik tombol 'Upload Evaluasi' untuk menambahkan dokumen",
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
                  rows: uploads.asMap().entries.map((entry) {
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

