import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../theme/app_colors.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int? _selectedTab; // null = none selected, 0-3 = tab index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ikhtisar Kinerja & SDM",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monitoring durasi kerja, evaluasi, dan status kontrak karyawan.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-employee');
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Buat PKWT Baru"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Stats Cards Row (Tabs)
            Consumer<EmployeeProvider>(
              builder: (context, employeeData, _) {
                final totalKaryawan = employeeData.employees.length;
                final karyawanAktif = employeeData.employees.where((e) => e.hariMenujuExpired > 30).length;
                final pkwtExpiring = employeeData.expiringContracts.length;
                final evaluasiTertunda = employeeData.evaluations.length;
                
                // Calculate average work duration
                double avgWorkDuration = 0;
                if (employeeData.employees.isNotEmpty) {
                  double totalDays = 0;
                  for (var emp in employeeData.employees) {
                    totalDays += DateTime.now().difference(emp.tglMulai).inDays;
                  }
                  avgWorkDuration = (totalDays / employeeData.employees.length) / 365;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildTabCard(
                        index: 0,
                        icon: Icons.people_alt_outlined,
                        iconBgColor: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF6366F1),
                        label: "Karyawan Aktif",
                        value: "$totalKaryawan",
                        badge: "+12%",
                        badgeColor: const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTabCard(
                        index: 1,
                        icon: Icons.access_time_outlined,
                        iconBgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFF59E0B),
                        label: "Rata-rata Masa Kerja",
                        value: avgWorkDuration.toStringAsFixed(1),
                        valueSuffix: " Tahun",
                        badge: "+0.3 Thn",
                        badgeColor: const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTabCard(
                        index: 2,
                        icon: Icons.warning_amber_outlined,
                        iconBgColor: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFEF4444),
                        label: "PKWT Segera Habis",
                        value: "$pkwtExpiring",
                        badge: "Perlu Tindakan",
                        badgeColor: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTabCard(
                        index: 3,
                        icon: Icons.assignment_outlined,
                        iconBgColor: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF8B5CF6),
                        label: "Evaluasi Tertunda",
                        value: "$evaluasiTertunda",
                        badge: "Pending",
                        badgeColor: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Detail Section based on selected tab
            if (_selectedTab != null) ...[
              const SizedBox(height: 24),
              _buildDetailSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabCard({
    required int index,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    String valueSuffix = "",
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedTab == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = _selectedTab == index ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
                ? Border.all(color: iconColor, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? iconColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (badge.startsWith('+'))
                              Icon(Icons.trending_up, size: 14, color: badgeColor),
                            if (badge.startsWith('+')) const SizedBox(width: 4),
                            Text(
                              badge,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (valueSuffix.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        valueSuffix,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    switch (_selectedTab) {
      case 0:
        return _buildKaryawanAktifSection();
      case 1:
        return _buildMasaKerjaSection();
      case 2:
        return _buildPkwtExpiringSection();
      case 3:
        return _buildEvaluasiSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _selectedTab = null),
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildKaryawanAktifSection() {
    return _buildSectionContainer(
      title: "Daftar Karyawan Aktif",
      icon: Icons.people_alt_outlined,
      color: const Color(0xFF6366F1),
      child: Consumer<EmployeeProvider>(
        builder: (context, data, _) {
          final employees = data.employees.take(5).toList();
          if (employees.isEmpty) {
            return const Center(child: Text("Belum ada data karyawan"));
          }
          return Column(
            children: employees.map((emp) => _buildEmployeeRow(
              name: emp.nama,
              email: emp.email,
              status: "Aktif",
              statusColor: const Color(0xFF22C55E),
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMasaKerjaSection() {
    return _buildSectionContainer(
      title: "Distribusi Masa Kerja",
      icon: Icons.access_time_outlined,
      color: const Color(0xFFF59E0B),
      child: Consumer<EmployeeProvider>(
        builder: (context, data, _) {
          // Group employees by work duration
          int lessThan1 = 0, oneToThree = 0, threeToFive = 0, moreThan5 = 0;
          for (var emp in data.employees) {
            final years = DateTime.now().difference(emp.tglMulai).inDays / 365;
            if (years < 1) lessThan1++;
            else if (years < 3) oneToThree++;
            else if (years < 5) threeToFive++;
            else moreThan5++;
          }
          
          return Column(
            children: [
              _buildDurationRow("< 1 Tahun", lessThan1, const Color(0xFFBFDBFE)),
              _buildDurationRow("1-3 Tahun", oneToThree, const Color(0xFF93C5FD)),
              _buildDurationRow("3-5 Tahun", threeToFive, const Color(0xFF3B82F6)),
              _buildDurationRow("> 5 Tahun", moreThan5, const Color(0xFF1D4ED8)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDurationRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            "$count karyawan",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPkwtExpiringSection() {
    return _buildSectionContainer(
      title: "PKWT Segera Berakhir",
      icon: Icons.warning_amber_outlined,
      color: const Color(0xFFEF4444),
      child: Consumer<EmployeeProvider>(
        builder: (context, data, _) {
          final expiring = data.expiringContracts;
          if (expiring.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 12),
                    Text("Tidak ada kontrak yang akan berakhir", 
                      style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: expiring.map((emp) => _buildEmployeeRow(
              name: emp.nama,
              email: "Sisa ${emp.hariMenujuExpired} hari",
              status: emp.hariMenujuExpired <= 7 ? "Urgent" : "Warning",
              statusColor: emp.hariMenujuExpired <= 7 
                  ? const Color(0xFFEF4444) 
                  : const Color(0xFFF59E0B),
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEvaluasiSection() {
    return _buildSectionContainer(
      title: "Evaluasi Tertunda",
      icon: Icons.assignment_outlined,
      color: const Color(0xFF8B5CF6),
      child: Column(
        children: [
          _buildEvaluationItem(
            title: "Q3 Performance Review",
            subtitle: "Marketing Dept • 4 Karyawan",
            deadline: "Due: 20 Des 2024",
          ),
          const SizedBox(height: 12),
          _buildEvaluationItem(
            title: "Probation Review",
            subtitle: "IT Dept • 2 Karyawan",
            deadline: "Due: 25 Des 2024",
          ),
          const SizedBox(height: 12),
          _buildEvaluationItem(
            title: "Annual Review",
            subtitle: "HR Dept • 3 Karyawan",
            deadline: "Due: 30 Des 2024",
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow({
    required String name, 
    required String email,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationItem({
    required String title, 
    required String subtitle,
    required String deadline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(deadline, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text("Mulai", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
