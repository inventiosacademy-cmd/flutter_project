import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/karyawan.dart';
import '../providers/prov_evaluation_upload.dart';
import '../services/evaluation_upload_service.dart';
import '../services/pdf_generator.dart';
import '../theme/warna.dart';

/// Dialog dua-fase untuk Evaluasi Manual:
///   Fase 1 – Preview PDF template blank (nama & posisi terisi) + Download / Print
///   Fase 2 – Upload file PDF evaluasi yang sudah diisi, disimpan di detail karyawan
class ManualEvaluationDialog extends StatefulWidget {
  final Employee employee;

  const ManualEvaluationDialog({super.key, required this.employee});

  static Future<void> show(BuildContext context, Employee employee) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => ManualEvaluationDialog(employee: employee),
    );
  }

  @override
  State<ManualEvaluationDialog> createState() => _ManualEvaluationDialogState();
}

enum _EvalMainPhase { preview, upload }

class _ManualEvaluationDialogState extends State<ManualEvaluationDialog> {
  // ------------------------------------------------------------------ state
  _EvalMainPhase _phase = _EvalMainPhase.preview;

  // Phase-1 (preview)
  Uint8List? _pdfBytes;
  List<Uint8List> _pdfPages = [];
  bool _isPdfLoading = true;
  double _zoomLevel = 1.0;
  int _activePage = 1;
  final ScrollController _scrollController = ScrollController();

  // Phase-2 (upload)
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  final _uploadService = EvaluationUploadService();

  // ------------------------------------------------------------------ init
  @override
  void initState() {
    super.initState();
    _generateBlankPdf();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ helpers
  void _handleScroll() {
    if (_pdfPages.isEmpty) return;
    final pageHeight = 840.0 * _zoomLevel;
    final newPage = (_scrollController.offset / pageHeight).floor() + 1;
    if (newPage != _activePage &&
        newPage > 0 &&
        newPage <= _pdfPages.length) {
      setState(() => _activePage = newPage);
    }
  }

  Future<void> _generateBlankPdf() async {
    try {
      final bytes = await EvaluasiPdfGenerator.generateBlankPdf(widget.employee);
      final pages = <Uint8List>[];
      await for (final page in Printing.raster(bytes, dpi: 200)) {
        pages.add(await page.toPng());
      }
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _pdfPages = pages;
          _isPdfLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ManualEvaluationDialog: error generating PDF: $e');
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    final safeName =
        'evaluasi_manual_${widget.employee.nama.replaceAll(' ', '_')}';
    await FileSaver.instance.saveFile(
      name: safeName,
      bytes: _pdfBytes!,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
    _switchToUpload();
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    final bytes = _pdfBytes!;
    await Printing.layoutPdf(onLayout: (_) => bytes);
    _switchToUpload();
  }

  void _switchToUpload() {
    if (mounted) setState(() => _phase = _EvalMainPhase.upload);
  }

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
        const SnackBar(
          content: Text('Pilih file PDF evaluasi terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final evaluationUpload = await _uploadService.uploadEvaluationPdf(
        employeeId: widget.employee.id,
        pdfFile: _selectedFile!,
        pkwtKe: widget.employee.pkwtKe,
      );

      if (mounted) {
        await Provider.of<EvaluationUploadProvider>(context, listen: false)
            .addEvaluationUpload(evaluationUpload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluasi manual berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
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

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: _phase == _EvalMainPhase.preview
          ? _buildPreviewPhase()
          : _buildUploadPhase(),
    );
  }

  // ------------------------------------------------------------------ Phase 1: Preview
  Widget _buildPreviewPhase() {
    if (_isPdfLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // Top header
        _buildDialogHeader('Template Evaluasi Manual – ${widget.employee.nama}'),

        // Toolbar
        _buildPreviewToolbar(),

        // Preview content
        Expanded(
          child: Row(
            children: [
              // Sidebar thumbnails
              Container(
                width: 180,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pdfPages.length,
                  itemBuilder: (context, index) {
                    final isActive = _activePage == index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                            index * 840.0 * _zoomLevel,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primaryBlue
                                      : const Color(0xFFE5E7EB),
                                  width: isActive ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.memory(_pdfPages[index],
                                    fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main preview
              Expanded(
                child: Container(
                  color: const Color(0xFFF3F4F6),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 40),
                    itemCount: _pdfPages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.memory(
                            _pdfPages[index],
                            width: 850 * _zoomLevel,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Info footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: const Color(0xFFFFF7ED),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16,
                  color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setelah download atau print template ini, Anda akan diminta untuk mengupload '
                  'file evaluasi yang sudah diisi.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          // Zoom controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => setState(
                      () => _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0)),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: Colors.grey.shade600,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => setState(
                      () => _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0)),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          const Spacer(),

          // Print
          OutlinedButton.icon(
            onPressed: _pdfBytes == null ? null : _printPdf,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              backgroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 12),

          // Download
          ElevatedButton.icon(
            onPressed: _pdfBytes == null ? null : _downloadPdf,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ Phase 2: Upload
  Widget _buildUploadPhase() {
    return SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildDialogHeader('Simpan Evaluasi Manual – ${widget.employee.nama}'),

          // Body
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppColors.primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Template sudah di-download/print. Silakan upload file PDF evaluasi '
                          'yang sudah diisi untuk ${widget.employee.nama} '
                          '(PKWT ke-${widget.employee.pkwtKe}).',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // File picker area
                InkWell(
                  onTap: _isUploading ? null : _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFile != null
                            ? AppColors.primaryBlue
                            : Colors.grey.shade300,
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
                          _selectedFile != null
                              ? Icons.check_circle
                              : Icons.cloud_upload,
                          size: 48,
                          color: _selectedFile != null
                              ? AppColors.primaryBlue
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFile != null
                              ? _selectedFile!.name
                              : 'Klik untuk pilih file PDF evaluasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedFile != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedFile != null
                                ? AppColors.primaryBlue
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Mengupload...',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isUploading) ...[
                      TextButton(
                        onPressed: () =>
                            setState(() => _phase = _EvalMainPhase.preview),
                        child: const Text('← Kembali ke Preview'),
                      ),
                      const SizedBox(width: 8),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Icon(Icons.upload),
                      label:
                          Text(_isUploading ? 'Menyimpan...' : 'Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ shared
  Widget _buildDialogHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_outlined,
                color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isUploading)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}
