import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/karyawan.dart';
import '../providers/prov_evaluation_upload.dart';
import '../services/pdf_generator.dart';
import '../theme/warna.dart';

/// Dialog untuk Evaluasi Manual:
///   Preview PDF template blank (nama & posisi terisi) + Download / Print
///   Upload file disimpan di bagian Riwayat Evaluasi pada detail karyawan.
class ManualEvaluationDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback? onPrinted;

  const ManualEvaluationDialog({super.key, required this.employee, this.onPrinted});

  static Future<void> show(BuildContext context, Employee employee, {VoidCallback? onPrinted}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => ManualEvaluationDialog(employee: employee, onPrinted: onPrinted),
    );
  }

  @override
  State<ManualEvaluationDialog> createState() => _ManualEvaluationDialogState();
}

class _ManualEvaluationDialogState extends State<ManualEvaluationDialog> {
  // ------------------------------------------------------------------ state
  Uint8List? _pdfBytes;
  List<Uint8List> _pdfPages = [];
  bool _isPdfLoading = true;
  double _zoomLevel = 1.0;
  int _activePage = 1;
  final ScrollController _scrollController = ScrollController();

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
    if (mounted) {
      // Mark as pending so it appears in Riwayat Evaluasi with 'Belum Upload'
      Provider.of<EvaluationUploadProvider>(context, listen: false)
          .markPendingManualEval(widget.employee.id, widget.employee.pkwtKe);
      Navigator.of(context).pop();
      widget.onPrinted?.call();
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    final bytes = _pdfBytes!;
    await Printing.layoutPdf(onLayout: (_) => bytes);
    if (mounted) {
      // Mark as pending so it appears in Riwayat Evaluasi with 'Belum Upload'
      Provider.of<EvaluationUploadProvider>(context, listen: false)
          .markPendingManualEval(widget.employee.id, widget.employee.pkwtKe);
      Navigator.of(context).pop();
      widget.onPrinted?.call();
    }
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    if (_isPdfLoading) {
      return const Dialog(
        child: SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: Column(
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
            color: const Color(0xFFF0FDF4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setelah download atau print, Anda akan diarahkan ke halaman Riwayat Evaluasi '
                    'untuk mengupload file evaluasi yang sudah diisi.',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
