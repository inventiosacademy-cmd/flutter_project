import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../theme/warna.dart';
import '../services/pdf_generator.dart';

class ModernPdfPreviewDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      backgroundColor: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Top Header (Logo, Filename, Meta)
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dibuat pada ${DateFormat('MMM dd, yyyy').format(evaluasiData.tanggalEvaluasi)} • 0.5 MB • Laporan Evaluasi",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
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
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          
          // Toolbar matching reference image
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                // Page Navigation (Placeholder Look)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.view_sidebar_outlined, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      const VerticalDivider(width: 1),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 20),
                      const Text(" 1 / 1 ", style: TextStyle(fontSize: 12)),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
                const Spacer(),
                // Zoom (Placeholder Look)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.remove, color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 12),
                      const Text("100%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Icon(Icons.add, color: Colors.grey.shade600, size: 18),
                    ],
                  ),
                ),
                const Spacer(),
                // Right Actions
                Icon(Icons.refresh_rounded, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 16),
                // Custom Print Button (Simplified Look to match image)
                OutlinedButton.icon(
                  onPressed: () async {
                    final pdfData = await EvaluasiPdfGenerator.generatePdf(evaluasiData);
                    await Printing.layoutPdf(onLayout: (format) => pdfData);
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text("Print"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 12),
                // Custom Download Button (Blue Solid)
                ElevatedButton.icon(
                  onPressed: () async {
                    final bytes = await EvaluasiPdfGenerator.generatePdf(evaluasiData);
                    await FileSaver.instance.saveFile(
                      name: fileName.replaceAll('.pdf', ''),
                      bytes: bytes,
                      ext: 'pdf',
                      mimeType: MimeType.pdf,
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Download"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          
          // Main Content: Sidebar + PDF
          Expanded(
            child: Row(
              children: [
                // Left Sidebar (Thumbnails placeholder)
                Container(
                  width: 160,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description, color: Colors.grey.shade300, size: 64),
                            const SizedBox(height: 8),
                            const Text("1", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                // PDF Viewer area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF3F4F6),
                    child: PdfPreview(
                      build: (format) => EvaluasiPdfGenerator.generatePdf(evaluasiData),
                      allowPrinting: false, // Using our custom button
                      allowSharing: false,  // Using our custom button
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      pdfFileName: fileName,
                      loadingWidget: const Center(child: CircularProgressIndicator()),
                      padding: const EdgeInsets.all(32),
                      useActions: false, // Hide the default built-in toolbar
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
