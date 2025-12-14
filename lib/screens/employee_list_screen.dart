import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employee_provider.dart';
import '../widgets/app_drawer.dart';
import 'employee_form_screen.dart';
import 'evaluation_form_screen.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Karyawan")),
      drawer: const AppDrawer(),
      body: Consumer<EmployeeProvider>(
        builder: (context, data, _) {
          final employees = data.employees;
          if (employees.isEmpty) {
            return const Center(child: Text("Belum ada data karyawan."));
          }
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (ctx, i) {
              final e = employees[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(e.nama),
                  subtitle: Text("Masa Kerja: ${e.masaKerja}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assignment_add, color: Colors.blue),
                        tooltip: "Evaluasi",
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => EvaluationFormScreen(employee: e)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        tooltip: "Detail",
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Detail: ${e.nama}"),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Email: ${e.email}"),
                                    Text("No HP: ${e.noHp}"),
                                    Text("Alamat: ${e.alamat}"),
                                    const Divider(),
                                    Text("Tgl Mulai: ${DateFormat('dd/MM/yyyy').format(e.tglMulai)}"),
                                    Text("Tgl Selesai: ${DateFormat('dd/MM/yyyy').format(e.tglSelesai)}"),
                                    Text("Sisa Hari: ${e.hariMenujuExpired} hari"),
                                    const SizedBox(height: 10),
                                    const Text("Riwayat Evaluasi:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...data.getEvaluations(e.id).map((ev) => Text("- [${DateFormat('dd/MM').format(ev.date)}] Skor ${ev.score}: ${ev.notes}")),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const EmployeeFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
