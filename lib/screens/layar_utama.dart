2import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/karyawan.dart';
import '../providers/prov_auth.dart' as app_auth;
import '../theme/warna.dart';
import 'konten_dashboard.dart';
import 'konten_tambah_karyawan.dart';
import 'konten_detail_karyawan.dart';
import 'konten_riwayat_evaluasi.dart';
import 'form_evaluasi.dart';
import 'konten_pengaturan.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showDetailKaryawan = false;
  Employee? _detailEmployee;
  
  // Missing variables restored
  bool _showTambahKaryawan = false;
  bool _showEvaluasi = false;
  bool _showRiwayatEvaluasi = false;
  // State for Edit Mode
  Employee? _editEmployee;
  Employee? _evaluasiEmployee;

  void _onMenuTap(int index) {
    setState(() {
      _showTambahKaryawan = false;
      _showEvaluasi = false;
      _showDetailKaryawan = false;
      _showRiwayatEvaluasi = false;
      _editEmployee = null; // Reset
      _detailEmployee = null;
      _evaluasiEmployee = null;
      
      if (index == 0) {
        _selectedIndex = index;
      } else if (index == 1) {
        _showRiwayatEvaluasi = true;
        _selectedIndex = index;
      } else if (index == 2) {
        // Settings
        _selectedIndex = index;
      }
    });
  }

  void _navigateToTambahKaryawan() {
    setState(() {
      _showTambahKaryawan = true;
      _editEmployee = null;
      _showEvaluasi = false;
      _showDetailKaryawan = false;
    });
  }

  void _navigateToEditKaryawan(Employee employee) {
    setState(() {
      _showTambahKaryawan = true;
      _editEmployee = employee;
      _showEvaluasi = false;
      _showDetailKaryawan = false;
    });
  }

  void _navigateToEvaluasi(Employee employee) {
    setState(() {
      _showEvaluasi = true;
      _showTambahKaryawan = false;
      _showDetailKaryawan = false;
      _evaluasiEmployee = employee;
    });
  }

  void _navigateToDetail(Employee employee) {
    setState(() {
      _showDetailKaryawan = true;
      _showTambahKaryawan = false;
      _showEvaluasi = false;
      _detailEmployee = employee;
    });
  }

  void _navigateBack() {
    setState(() {
      _showTambahKaryawan = false;
      _showEvaluasi = false;
      _showDetailKaryawan = false;
      _showRiwayatEvaluasi = false;
      _evaluasiEmployee = null;
      _detailEmployee = null;
    });
  }

  Widget _buildContent() {
    if (_showTambahKaryawan) {
      return KontenTambahKaryawan(
        onBack: _navigateBack,
        employeeToEdit: _editEmployee,
      );
    }
    
    if (_showEvaluasi && _evaluasiEmployee != null) {
      return KontenEvaluasi(employee: _evaluasiEmployee!, onBack: _navigateBack);
    }
    
    if (_showDetailKaryawan && _detailEmployee != null) {
      return KontenDetailKaryawan(employee: _detailEmployee!, onBack: _navigateBack);
    }
    
    if (_showRiwayatEvaluasi) {
      return KontenRiwayatEvaluasi(onBuatEvaluasi: _navigateToTambahKaryawan);
    }

    if (_selectedIndex == 2) {
      return const SettingsContent();
    }
    
    return DashboardContent(
      onTambahKaryawan: _navigateToTambahKaryawan,
      onEvaluasi: _navigateToEvaluasi,
      onViewDetail: _navigateToDetail,
      onEdit: _navigateToEditKaryawan,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permanent Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        children: [
          // User Info (Real-time from Provider)
          Consumer<app_auth.AuthProvider>(
            builder: (context, authProvider, _) {
              final displayName = authProvider.displayName;
              final jobTitle = authProvider.jobTitle;
              final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

              return Container(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              jobTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          const SizedBox(height: 8),

          // Menu Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Dashboard',
                    index: 0,
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Riwayat Evaluasi',
                    index: 1,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Pengaturan',
                    index: 2,
                  ),
                ],
              ),
            ),
          ),

          // Logout Section removed as requested
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = !_showTambahKaryawan && !_showEvaluasi && !_showDetailKaryawan && _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onMenuTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon, 
                  color: isActive ? AppColors.primaryBlue : Colors.grey.shade600, 
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.primaryBlue : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text("Konfirmasi Keluar"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari aplikasi?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<app_auth.AuthProvider>(context, listen: false).logout();
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }
}
