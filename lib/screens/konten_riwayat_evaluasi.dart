import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/prov_evaluasi.dart';
import '../models/evaluasi.dart';
import '../theme/warna.dart';

class KontenRiwayatEvaluasi extends StatefulWidget {
  final VoidCallback? onBuatEvaluasi;

  const KontenRiwayatEvaluasi({
    super.key,
    this.onBuatEvaluasi,
  });

  @override
  State<KontenRiwayatEvaluasi> createState() => _KontenRiwayatEvaluasiState();
}

class _KontenRiwayatEvaluasiState extends State<KontenRiwayatEvaluasi> {
  String _selectedTimeFilter = 'all';
  EvaluasiStatus? _selectedStatusFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;

  final List<Map<String, String>> _timeFilters = [
    {'value': 'all', 'label': 'Semua Waktu'},
    {'value': 'thisMonth', 'label': 'Bulan Ini'},
    {'value': '3months', 'label': '3 Bulan Terakhir'},
    {'value': '6months', 'label': '6 Bulan Terakhir'},
    {'value': 'thisYear', 'label': 'Tahun Ini'},
  ];

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
                      "Riwayat Evaluasi",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Kelola dan pantau riwayat evaluasi karyawan.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onBuatEvaluasi,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Buat Evaluasi Baru"),
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

            const SizedBox(height: 28),

            // Stats Cards
            Consumer<EvaluasiProvider>(
              builder: (context, provider, _) {
                final stats = provider.getStats();
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.assessment_outlined,
                        iconBgColor: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF6366F1),
                        label: "Total Evaluasi",
                        value: "${stats['total']}",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.edit_note_outlined,
                        iconBgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFF59E0B),
                        label: "Draft",
                        value: "${stats['draft']}",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.pending_outlined,
                        iconBgColor: const Color(0xFFDDD6FE),
                        iconColor: const Color(0xFF8B5CF6),
                        label: "Belum TTD Atasan",
                        value: "${stats['belumTTD']}",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle_outline,
                        iconBgColor: const Color(0xFFD1FAE5),
                        iconColor: const Color(0xFF22C55E),
                        label: "Selesai",
                        value: "${stats['selesai']}",
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Filters and Table
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
                  // Search and Filters Row
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
                            hintText: "Cari nama karyawan atau periode...",
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
                      _buildTimeFilterDropdown(),
                      const SizedBox(width: 12),
                      _buildStatusFilterDropdown(),
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
                        _buildTableHeader("TANGGAL", flex: 1),
                        _buildTableHeader("NILAI", flex: 1, center: true),
                        _buildTableHeader("STATUS", flex: 1, center: true),
                        _buildTableHeader("AKSI", flex: 1, center: true),
                      ],
                    ),
                  ),

                  // Table Content
                  Consumer<EvaluasiProvider>(
                    builder: (context, provider, _) {
                      final allEvaluasi = provider.getFilteredEvaluasi(
                        timeFilter: _selectedTimeFilter,
                        statusFilter: _selectedStatusFilter,
                        searchQuery: _searchQuery,
                      );
                      final totalData = provider.evaluasiList.length;
                      final totalFiltered = allEvaluasi.length;
                      
                      // Pagination
                      final totalPages = (totalFiltered / _itemsPerPage).ceil();
                      final startIndex = (_currentPage - 1) * _itemsPerPage;
                      final endIndex = (startIndex + _itemsPerPage).clamp(0, totalFiltered);
                      final evaluasiList = allEvaluasi.sublist(
                        startIndex.clamp(0, totalFiltered),
                        endIndex,
                      );

                      if (allEvaluasi.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.assessment_outlined, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? "Tidak ada hasil untuk \"$_searchQuery\""
                                      : "Belum ada data evaluasi",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          ...evaluasiList.map((evaluasi) {
                            return _buildEvaluasiRow(evaluasi, provider);
                          }).toList(),
                          // Pagination controls
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
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
                                    Text("dari $totalFiltered data", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildPageButton("<", false, onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
                                    const SizedBox(width: 4),
                                    ...List.generate(totalPages.clamp(1, 5), (index) {
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
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: _buildPageButton(
                                          "$pageNum",
                                          _currentPage == pageNum,
                                          onTap: () => setState(() => _currentPage = pageNum),
                                        ),
                                      );
                                    }),
                                    _buildPageButton(">", false, onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildTimeFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Waktu: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTimeFilter,
              icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              items: _timeFilters.map((filter) {
                return DropdownMenuItem(
                  value: filter['value'],
                  child: Text(filter['label']!),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTimeFilter = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterDropdown() {
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
            child: DropdownButton<EvaluasiStatus?>(
              value: _selectedStatusFilter,
              icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua')),
                ...EvaluasiStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _selectedStatusFilter = value),
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

  Widget _buildEvaluasiRow(Evaluasi evaluasi, EvaluasiProvider provider) {
    Color statusColor;
    Color statusBgColor;

    switch (evaluasi.status) {
      case EvaluasiStatus.draft:
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFFEF3C7);
        break;
      case EvaluasiStatus.belumTTD:
        statusColor = const Color(0xFF8B5CF6);
        statusBgColor = const Color(0xFFF3E8FF);
        break;
      case EvaluasiStatus.selesai:
        statusColor = const Color(0xFF22C55E);
        statusBgColor = const Color(0xFFD1FAE5);
        break;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evaluasi.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  evaluasi.employeePosition,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Tanggal
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('dd MMM yyyy').format(evaluasi.tanggalEvaluasi),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          // Nilai
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getNilaiColor(evaluasi.nilaiKinerja).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getNilaiColor(evaluasi.nilaiKinerja).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  evaluasi.nilaiKinerja,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getNilaiColor(evaluasi.nilaiKinerja),
                  ),
                ),
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Center(
              child: Tooltip(
                message: evaluasi.status.label,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getShortStatusLabel(evaluasi.status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(Icons.more_horiz, size: 20, color: Colors.grey.shade600),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(evaluasi.id, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryBlue),
                          SizedBox(width: 12),
                          Text('Lihat Detail'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 12),
                          Text('Hapus', style: TextStyle(color: Color(0xFFEF4444))),
                        ],
                      ),
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

  Color _getNilaiColor(String nilai) {
    if (nilai.startsWith('A')) {
      return const Color(0xFF059669);
    } else if (nilai.startsWith('B')) {
      return AppColors.primaryBlue;
    } else if (nilai.startsWith('C')) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  String _getShortStatusLabel(EvaluasiStatus status) {
    switch (status) {
      case EvaluasiStatus.draft:
        return 'Draft';
      case EvaluasiStatus.belumTTD:
        return 'Belum TTD';
      case EvaluasiStatus.selesai:
        return 'Selesai';
    }
  }

  Widget _buildPageButton(String label, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          border: Border.all(color: isActive ? AppColors.primaryBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : onTap != null ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String id, EvaluasiProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text("Hapus Evaluasi"),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin menghapus evaluasi ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deleteEvaluasi(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Evaluasi berhasil dihapus")),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
