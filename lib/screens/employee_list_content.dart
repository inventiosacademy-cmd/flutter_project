import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employee_provider.dart';
import '../theme/app_colors.dart';
import 'employee_form_screen.dart';
import 'evaluation_form_screen.dart';

class EmployeeListContent extends StatefulWidget {
  const EmployeeListContent({super.key});

  @override
  State<EmployeeListContent> createState() => _EmployeeListContentState();
}

class _EmployeeListContentState extends State<EmployeeListContent> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daftar Karyawan",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Kelola data karyawan, status kontrak, dan evaluasi kinerja.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: const Text("Import Data"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const EmployeeFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Tambah Karyawan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Stats Cards
            Consumer<EmployeeProvider>(
              builder: (context, data, _) {
                final total = data.employees.length;
                final aktif = data.employees.where((e) => e.hariMenujuExpired > 30).length;

                return Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      icon: Icons.people_alt_outlined,
                      iconBgColor: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF6366F1),
                      label: "Total Karyawan",
                      value: "$total",
                      badge: "+5% bulan ini",
                      badgeColor: const Color(0xFF22C55E),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF22C55E),
                      label: "Karyawan Aktif",
                      value: "$aktif",
                      badge: "+2% bulan ini",
                      badgeColor: const Color(0xFF22C55E),
                    )),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Search and Filters
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search and Filter Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Cari nama karyawan, ID, atau posisi...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown("Semua Dept."),
                      const SizedBox(width: 12),
                      _buildFilterDropdown("Status Kontrak"),
                      const SizedBox(width: 12),
                      _buildFilterDropdown("Durasi Kerja"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader("KARYAWAN", flex: 2),
                        _buildTableHeader("ID KARYAWAN", flex: 1),
                        _buildTableHeader("DEPARTEMEN", flex: 1),
                        _buildTableHeader("DURASI KERJA", flex: 1),
                        _buildTableHeader("STATUS KONTRAK", flex: 2),
                        _buildTableHeader("AKSI", flex: 1, center: true),
                      ],
                    ),
                  ),

                  // Table Content
                  Consumer<EmployeeProvider>(
                    builder: (context, data, _) {
                      final employees = data.employees
                          .where((e) => e.nama.toLowerCase().contains(_searchQuery) ||
                                       e.email.toLowerCase().contains(_searchQuery))
                          .toList();

                      if (employees.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? "Tidak ada hasil untuk \"$_searchQuery\""
                                      : "Belum ada data karyawan",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: employees.asMap().entries.map((entry) {
                          final index = entry.key;
                          final emp = entry.value;
                          return _buildEmployeeRow(context, emp, index, data);
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Pagination
                  Consumer<EmployeeProvider>(
                    builder: (context, data, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text("Menampilkan", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Text("10", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("dari ${data.employees.length} data", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                          Row(
                            children: [
                              _buildPageButton("<", false),
                              _buildPageButton("1", true),
                              _buildPageButton("2", false),
                              _buildPageButton("3", false),
                              Text("...", style: TextStyle(color: Colors.grey.shade400)),
                              _buildPageButton("12", false),
                              _buildPageButton(">", false),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (badge.startsWith('+'))
                      Icon(Icons.trending_up, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badge,
                      style: TextStyle(fontSize: 12, color: badgeColor),
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

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label, {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmployeeRow(BuildContext context, dynamic emp, int index, EmployeeProvider data) {
    final daysWorked = DateTime.now().difference(emp.tglMulai).inDays;
    final years = daysWorked ~/ 365;
    final months = (daysWorked % 365) ~/ 30;
    final durationText = years > 0 ? "$years Thn $months Bln" : "$months Bulan";
    final daysLeft = emp.hariMenujuExpired;
    
    String statusText;
    Color statusColor;
    Color statusBgColor;
    String? actionBadge;
    Color? actionBadgeColor;
    
    if (daysLeft <= 0) {
      statusText = "Expired";
      statusColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFFEE2E2);
    } else if (daysLeft <= 14) {
      statusText = "Habis $daysLeft Hari";
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFFEF3C7);
      actionBadge = "Perpanjang";
      actionBadgeColor = const Color(0xFF22C55E);
    } else if (daysLeft <= 30) {
      statusText = "Perlu Evaluasi";
      statusColor = const Color(0xFF8B5CF6);
      statusBgColor = const Color(0xFFF3E8FF);
    } else {
      statusText = "Aktif (PKWTT)";
      statusColor = const Color(0xFF22C55E);
      statusBgColor = const Color(0xFFD1FAE5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // Employee Info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(index),
                  child: Text(
                    emp.nama.isNotEmpty ? emp.nama[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      emp.email.contains('@') ? emp.email.split('@')[0] : "Staff",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ID
          Expanded(
            flex: 1,
            child: Text(
              "EMP-${DateTime.now().year}-${(index + 1).toString().padLeft(3, '0')}",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          // Department
          Expanded(
            flex: 1,
            child: Text(
              _getDepartment(index),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          // Duration
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(durationText, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                Text(
                  "Sejak ${DateFormat('MMM yyyy').format(emp.tglMulai)}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
                  ),
                ),
                if (actionBadge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionBadgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      actionBadge,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _showDetailDialog(context, emp, data),
                  icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.grey.shade500),
                  tooltip: "Lihat Detail",
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                  onSelected: (value) {
                    if (value == 'evaluate') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => EvaluationFormScreen(employee: emp)),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'evaluate', child: Text('Evaluasi')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  String _getDepartment(int index) {
    final depts = ["IT Dept.", "Human Resources", "Sales & Marketing", "Product Design", "Finance"];
    return depts[index % depts.length];
  }

  Widget _buildPageButton(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isActive ? AppColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, dynamic e, EmployeeProvider data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    e.nama.isNotEmpty ? e.nama[0].toUpperCase() : "?",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(e.email, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.phone_rounded, "Telepon", e.noHp),
            _buildInfoRow(Icons.home_rounded, "Alamat", e.alamat),
            const Divider(height: 32),
            _buildInfoRow(Icons.calendar_today_rounded, "Mulai Kerja", DateFormat('dd MMMM yyyy').format(e.tglMulai)),
            _buildInfoRow(Icons.event_rounded, "Berakhir", DateFormat('dd MMMM yyyy').format(e.tglSelesai)),
            _buildInfoRow(Icons.timelapse_rounded, "Sisa Kontrak", "${e.hariMenujuExpired} hari"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
