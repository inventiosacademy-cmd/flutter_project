import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../theme/warna.dart';
import '../services/pdf_generator.dart';

class ModernPdfPreviewDialog extends StatefulWidget {
  final EvaluasiData evaluasiData;
  final String fileName;

  const ModernPdfPreviewDialog({
    super.key,
    required this.evaluasiData,
    required this.fileName,
  });

  static Future<void> show({
    required BuildContext context,
    required EvaluasiData evaluasiData,
    required String fileName,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ModernPdfPreviewDialog(
        evaluasiData: evaluasiData,
        fileName: fileName,
      ),
    );
  }

  @override
  State<ModernPdfPreviewDialog> createState() => _ModernPdfPreviewDialogState();
}

class _ModernPdfPreviewDialogState extends State<ModernPdfPreviewDialog> {
  List<Uint8List> _pages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _activePage = 1;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPdfPages();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_pages.isEmpty) return;
    double offset = _scrollController.offset;
    // Adjust page calculation based on current zoom
    double pageHeight = 840.0 * _zoomLevel;
    int newPage = (offset / pageHeight).floor() + 1;
    if (newPage != _activePage && newPage > 0 && newPage <= _pages.length) {
      setState(() {
        _activePage = newPage;
      });
    }
  }

  void _updateZoom(double delta) {
    if (mounted) {
      setState(() {
        _zoomLevel = (_zoomLevel + delta).clamp(0.5, 3.0);
      });
    }
  }

  Future<void> _loadPdfPages() async {
    try {
      final pdfData = await EvaluasiPdfGenerator.generatePdf(widget.evaluasiData);
      final List<Uint8List> pageImages = [];
      
      await for (final page in Printing.raster(pdfData, dpi: 200)) { // Higher DPI for better zoom
        final png = await page.toPng();
        pageImages.add(png);
      }

      if (mounted) {
        setState(() {
          _pages = pageImages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading PDF pages: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToPage(int pageIndex) {
    double pageHeight = 840.0 * _zoomLevel;
    _scrollController.animateTo(
      pageIndex * pageHeight,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: _isLoading 
        ? const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()))
        : Column(
            children: [
              // 1. Top Information Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 20,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            "Dibuat pada ${DateFormat('MMM dd, yyyy').format(widget.evaluasiData.tanggalEvaluasi)} • 0.5 MB • Laporan Evaluasi",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),

              // 2. Main Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    const Spacer(),

                    // Zoom Controls
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
                            onPressed: () => _updateZoom(-0.25),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            color: Colors.grey.shade600,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "${(_zoomLevel * 100).toInt()}%",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => _updateZoom(0.25),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.refresh, size: 20, color: Colors.grey.shade600),
                      onPressed: () => setState(() => _zoomLevel = 1.0),
                    ),

                    const SizedBox(width: 24),

                    // Print Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        final pdfData = await EvaluasiPdfGenerator.generatePdf(widget.evaluasiData);
                        await Printing.layoutPdf(onLayout: (format) => pdfData);
                      },
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text("Print"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Download Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final bytes = await EvaluasiPdfGenerator.generatePdf(widget.evaluasiData);
                        await FileSaver.instance.saveFile(
                          name: widget.fileName.replaceAll('.pdf', ''),
                          bytes: bytes,
                          ext: 'pdf',
                          mimeType: MimeType.pdf,
                        );
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("Download"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8), // Deep blue from image
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 3. Main Content (Sidebar + Preview)
              Expanded(
                child: Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 200, // Slightly wider to match image proportion
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          bool isActive = _activePage == index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: GestureDetector(
                              onTap: () => _scrollToPage(index),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                                        width: isActive ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: isActive ? [
                                        BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.08), blurRadius: 10),
                                      ] : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Image.memory(_pages[index], fit: BoxFit.contain),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Main Preview area
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF3F4F6),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            return Padding(
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
                                    _pages[index], 
                                    width: 850 * _zoomLevel,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
