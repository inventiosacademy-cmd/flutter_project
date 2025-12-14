import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HR Dashboard"),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selamat Datang, Admin!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Check for expiring contracts
            Consumer<EmployeeProvider>(
              builder: (context, employeeData, child) {
                final expiring = employeeData.expiringContracts;
                if (expiring.isEmpty) {
                  return const Card(
                    color: Colors.green,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Semua kontrak aman.",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  color: Colors.orange[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.deepOrange),
                            const SizedBox(width: 10),
                            Text(
                              "Perhatian! ${expiring.length} Karyawan kontrak < 30 hari:",
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...expiring.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text("- ${e.nama} (Sisa: ${e.hariMenujuExpired} hari)"),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            // Generic Stats
            Consumer<EmployeeProvider>(
              builder: (context, employeeData, _) {
                 return Row(
                   children: [
                     _buildStatCard("Total Karyawan", "${employeeData.employees.length}", Colors.blue),
                     const SizedBox(width: 10),
                     // Add more stats here if needed
                   ],
                 );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
