import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/employee_list_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Menu HR'),
            automaticallyImplyLeading: false,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Data Karyawan'),
            onTap: () {
              // Kita belum buat EmployeeListScreen, tapi akan segera dibuat.
              // Menggunakan pushReplacement agar tidak menumpuk di stack
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const EmployeeListScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Provider.of<AuthProvider>(context, listen: false).logout();
              // Otomatis kembali ke LoginScreen karena logic di main.dart
            },
          ),
        ],
      ),
    );
  }
}
