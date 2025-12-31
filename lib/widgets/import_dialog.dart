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
              onTap: () {
                _handleFileUpload(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileUpload(BuildContext dialogContext) async {
    print("_handleFileUpload called");
    
    try {
      print("Starting file picker...");
      final employees = await ImportService().pickAndParseFile();
      print("Parsed ${employees.length} employees");
      print("Context mounted: ${dialogContext.mounted}");
      
      // Get navigator context BEFORE closing dialog - this stays valid
      final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
      final navigator = Navigator.of(dialogContext);
      
      if (!dialogContext.mounted) {
        print("ERROR: context not mounted!");
        return;
      }
      
      Navigator.pop(dialogContext);
      print("Dialog closed");
      
      if (employees.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Tidak ada data dalam file"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      print("Showing confirmation");
      final confirmed = await showDialog<bool>(
        context: navigator.context,
        builder: (ctx) => AlertDialog(
          title: const Text("Konfirmasi"),
          content: Text("Import ${employees.length} data?"),
          actions: [
            TextButton(
              onPressed: () {
                print("❌ USER CLICKED BATAL");
                Navigator.pop(ctx, false);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                print("✅ USER CLICKED IMPORT");
                Navigator.pop(ctx, true);
              },
              child: const Text("Import"),
            ),
          ],
        ),
      );

      print("📊 Confirmed: $confirmed");
      print("📊 Navigator context mounted: ${navigator.context.mounted}");

      if (confirmed == true) {
        print("✅ STARTING SAVE...");
        showDialog(
          context: navigator.context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Menyimpan..."),
              ],
            ),
          ),
        );

        try {
          print("🔥 Getting provider...");
          final provider = Provider.of<EmployeeProvider>(navigator.context, listen: false);
          print("🔥 Calling addEmployees(${employees.length})...");
          await provider.addEmployees(employees);
          print("✅ SAVED TO FIREBASE!");

          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("✅ Berhasil import ${employees.length} data"),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e, stack) {
          print("❌ SAVE ERROR: $e");
          print("Stack: $stack");
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("❌ Gagal: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("❌ User cancelled");
      }
    } catch (e, stack) {
      print("ERROR: $e");
      print("Stack: $stack");
    }
  }
}
