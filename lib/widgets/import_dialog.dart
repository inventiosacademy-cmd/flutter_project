import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/import_service.dart';
import '../providers/prov_karyawan.dart';
import '../theme/warna.dart';

class ImportDialog extends StatelessWidget {
  const ImportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Import Data Karyawan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Unduh template atau upload file Excel/CSV Anda.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded, color: Colors.green),
              ),
              title: const Text("Download Template Excel"),
              subtitle: const Text("Format .xlsx untuk pengisian data"),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ImportService().downloadTemplate();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Template berhasil diunduh dan dibuka"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Gagal mengunduh template: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file_rounded, color: AppColors.primaryBlue),
              ),
              title: const Text("Upload File"),
              subtitle: const Text("Support .xlsx, .xls, .csv"),
              onTap: () async {
                Navigator.pop(context);
                _handleFileUpload(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileUpload(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Memproses file..."),
          ],
        ),
      ),
    );

    try {
      final employees = await ImportService().pickAndParseFile();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        if (employees.isNotEmpty) {
          // Show confirmation
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Konfirmasi Import"),
              content: Text("Akan mengimport ${employees.length} data karyawan. Lanjutkan?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Import"),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            // Show saving loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Menyimpan data..."),
                  ],
                ),
              ),
            );

            await Provider.of<EmployeeProvider>(context, listen: false)
                .addEmployees(employees);

            if (context.mounted) {
              Navigator.pop(context); // Close saving loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Berhasil mengimport ${employees.length} data"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ada data yang ditemukan dalam file"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
