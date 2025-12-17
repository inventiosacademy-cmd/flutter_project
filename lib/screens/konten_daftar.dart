import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/prov_karyawan.dart';
import '../models/karyawan.dart';
import '../theme/warna.dart';

class EmployeeListContent extends StatefulWidget {
  final VoidCallback? onTambahKaryawan;
  final Function(Employee)? onEvaluasi;
  final Function(Employee)? onViewDetail;
  
  const EmployeeListContent({
    super.key, 
    this.onTambahKaryawan, 
    this.onEvaluasi,
    this.onViewDetail,
  });

  @override
  State<EmployeeListContent> createState() => _EmployeeListContentState();
}

class _EmployeeListContentState extends State<EmployeeListContent> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  String _selectedDept = 'Semua';
  String _selectedStatus = 'Semua';
  
  // Pagination states
  int _currentPage = 1;
  int _itemsPerPage = 10;
  
  final List<String> _deptList = ['Semua', 'IT', 'Human Resources', 'Finance', 'Marketing', 'Sales', 'Operations', 'Product', 'Legal'];
  final List<String> _statusList = ['Semua', 'Aktif', 'Segera Habis', 'Expired'];

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
                      onPressed: widget.onTambahKaryawan,
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
                final tidakAktif = data.employees.where((e) => e.hariMenujuExpired <= 0).length;
                final pkwtSegeraHabis = data.employees.where((e) => e.hariMenujuExpired > 0 && e.hariMenujuExpired <= 30).length;

                return Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      icon: Icons.people_alt_outlined,
                      iconBgColor: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF6366F1),
                      label: "Total Karyawan",
                      value: "$total",
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF22C55E),
                      label: "Karyawan Aktif",
                      value: "$aktif",
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      icon: Icons.cancel_outlined,
                      iconBgColor: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFEF4444),
                      label: "Tidak Aktif",
                      value: "$tidakAktif",
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      icon: Icons.warning_amber_outlined,
                      iconBgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFF59E0B),
                      label: "PKWT Segera Habis",
                      value: "$pkwtSegeraHabis",
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
                      _buildDeptDropdown(),
                      const SizedBox(width: 12),
                      _buildStatusDropdown(),
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
                        _buildTableHeader("MASA KERJA", flex: 1),
                        _buildTableHeader("SISA KONTRAK", flex: 1),
                        _buildTableHeader("STATUS", flex: 1),
                        _buildTableHeader("AKSI", flex: 1, center: true),
                      ],
                    ),
                  ),

                  // Table Content
                  Consumer<EmployeeProvider>(
                    builder: (context, data, _) {
                      var employees = data.employees
                          .where((e) => e.nama.toLowerCase().contains(_searchQuery) ||
                                       e.email.toLowerCase().contains(_searchQuery))
                          .toList();
                      
                      // Filter by department
                      if (_selectedDept != 'Semua') {
                        employees = employees.where((e) => e.departemen == _selectedDept).toList();
                      }
                      
                      // Filter by status
                      if (_selectedStatus != 'Semua') {
                        employees = employees.where((e) {
                          if (_selectedStatus == 'Aktif') return e.hariMenujuExpired > 30;
                          if (_selectedStatus == 'Segera Habis') return e.hariMenujuExpired > 0 && e.hariMenujuExpired <= 30;
                          if (_selectedStatus == 'Expired') return e.hariMenujuExpired <= 0;
                          return true;
                        }).toList();
                      }

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

                      // Paginate
                      final totalItems = employees.length;
                      if (totalItems == 0) {
                        return const SizedBox.shrink();
                      }
                      final totalPages = (totalItems / _itemsPerPage).ceil();
                      final safeCurrentPage = _currentPage.clamp(1, totalPages);
                      final startIndex = (safeCurrentPage - 1) * _itemsPerPage;
                      final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
                      final paginatedEmployees = employees.sublist(startIndex, endIndex);

                      return Column(
                        children: paginatedEmployees.asMap().entries.map((entry) {
                          final index = startIndex + entry.key;
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
                      // Apply same filters to get correct total
                      var filteredEmployees = data.employees
                          .where((e) => e.nama.toLowerCase().contains(_searchQuery) ||
                                       e.email.toLowerCase().contains(_searchQuery))
                          .toList();
                      
                      if (_selectedDept != 'Semua') {
                        filteredEmployees = filteredEmployees.where((e) => e.departemen == _selectedDept).toList();
                      }
                      
                      if (_selectedStatus != 'Semua') {
                        filteredEmployees = filteredEmployees.where((e) {
                          if (_selectedStatus == 'Aktif') return e.hariMenujuExpired > 30;
                          if (_selectedStatus == 'Segera Habis') return e.hariMenujuExpired > 0 && e.hariMenujuExpired <= 30;
                          if (_selectedStatus == 'Expired') return e.hariMenujuExpired <= 0;
                          return true;
                        }).toList();
                      }
                      
                      final totalItems = filteredEmployees.length;
                      final totalPages = totalItems == 0 ? 1 : (totalItems / _itemsPerPage).ceil();
                      final startItem = totalItems == 0 ? 0 : ((_currentPage - 1) * _itemsPerPage) + 1;
                      final endItem = (_currentPage * _itemsPerPage).clamp(0, totalItems);
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text("Menampilkan", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(width: 8),
                              PopupMenuButton<int>(
                                initialValue: _itemsPerPage,
                                onSelected: (val) => setState(() {
                                  _itemsPerPage = val;
                                  _currentPage = 1;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Text("$_itemsPerPage", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [5, 10, 25, 50].map((val) => 
                                  PopupMenuItem(value: val, child: Text("$val"))
                                ).toList(),
                              ),
                              const SizedBox(width: 8),
                              Text("dari $totalItems data", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                          Row(
                            children: [
                              // Previous button
                              _buildPageButton("<", false, onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
                              // Page buttons
                              ...List.generate(totalPages.clamp(0, 5), (index) {
                                int pageNum;
                                if (totalPages <= 5) {
                                  pageNum = index + 1;
                                } else if (_currentPage <= 3) {
                                  pageNum = index + 1;
                                } else if (_currentPage >= totalPages - 2) {
                                  pageNum = totalPages - 4 + index;
                                } else {
                                  pageNum = _currentPage - 2 + index;
                                }
                                return _buildPageButton("$pageNum", _currentPage == pageNum, onTap: () => setState(() => _currentPage = pageNum));
                              }),
                              if (totalPages > 5) ...[
                                Text("...", style: TextStyle(color: Colors.grey.shade400)),
                                _buildPageButton("$totalPages", _currentPage == totalPages, onTap: () => setState(() => _currentPage = totalPages)),
                              ],
                              // Next button
                              _buildPageButton(">", false, onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
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

  Widget _buildPageButton(String label, bool isActive, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isActive ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isActive ? Colors.white : onTap == null ? Colors.grey.shade400 : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Dept: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDept,
              icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              items: _deptList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedDept = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Status: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              items: _statusList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedStatus = v!),
            ),
          ),
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
    final daysWorked = DateTime.now().difference(emp.tglMasuk).inDays;
    final years = daysWorked ~/ 365;
    final months = (daysWorked % 365) ~/ 30;
    final durationText = years > 0 ? "$years Thn $months Bln" : "$months Bulan";
    final daysLeft = emp.hariMenujuExpired;
    
    String statusText;
    Color statusColor;
    Color statusBgColor;
    
    if (daysLeft <= 0) {
      statusText = "Expired";
      statusColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFFEE2E2);
    } else if (daysLeft <= 14) {
      statusText = "Segera Habis";
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFFEF3C7);
    } else if (daysLeft <= 30) {
      statusText = "Perlu Evaluasi";
      statusColor = const Color(0xFF8B5CF6);
      statusBgColor = const Color(0xFFF3E8FF);
    } else {
      statusText = "Aktif";
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
                      emp.posisi,
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
              emp.departemen,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          // Masa Kerja
          Expanded(
            flex: 1,
            child: Text(
              emp.masaKerja,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          // Sisa Kontrak
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysLeft <= 0 ? "Expired" : "$daysLeft hari", 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600,
                    color: daysLeft <= 0 ? const Color(0xFFEF4444) : 
                           daysLeft <= 30 ? const Color(0xFFF59E0B) : Colors.grey.shade700,
                  ),
                ),
                Text(
                  "Berakhir ${DateFormat('dd MMM yyyy').format(emp.tglPkwtBerakhir)}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 1,
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
              ],
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern Popup Menu
                Theme(
                  data: Theme.of(context).copyWith(
                    useMaterial3: true,
                    popupMenuTheme: PopupMenuThemeData(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      surfaceTintColor: Colors.white,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Icon(Icons.more_horiz, size: 20, color: Colors.grey.shade600),
                    ),
                    splashRadius: 24,
                    offset: const Offset(0, 40),
                    onSelected: (value) {
                      if (value == 'detail') {
                        widget.onViewDetail?.call(emp);
                      } else if (value == 'evaluate') {
                        widget.onEvaluasi?.call(emp);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryBlue),
                            const SizedBox(width: 12),
                            Text('Lihat Detail', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            Text('Edit', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'evaluate',
                        child: Row(
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            Text('Evaluasi', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 12),
                            const Text('Hapus', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            _buildInfoRow(Icons.work_rounded, "Posisi", e.posisi),
            _buildInfoRow(Icons.business_rounded, "Departemen", e.departemen),
            _buildInfoRow(Icons.supervisor_account_rounded, "Atasan", e.atasanLangsung),
            const Divider(height: 32),
            _buildInfoRow(Icons.calendar_today_rounded, "Mulai Kerja", DateFormat('dd MMMM yyyy').format(e.tglMasuk)),
            _buildInfoRow(Icons.event_rounded, "PKWT Berakhir", DateFormat('dd MMMM yyyy').format(e.tglPkwtBerakhir)),
            _buildInfoRow(Icons.description_rounded, "PKWT Ke-", "${e.pkwtKe}"),
            _buildInfoRow(Icons.timelapse_rounded, "Sisa Kontrak", "${e.hariMenujuExpired} hari"),
            _buildInfoRow(Icons.work_history_rounded, "Masa Kerja", e.masaKerja),
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
