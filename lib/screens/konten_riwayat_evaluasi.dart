import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/prov_evaluasi.dart';
import '../models/evaluasi.dart';
import '../theme/warna.dart';
import '../services/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../widgets/pdf_preview_dialog.dart';
import 'edit_evaluasi.dart';

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
  String? _selectedDivisiFilter;
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
                // ElevatedButton.icon(
                //   onPressed: widget.onBuatEvaluasi,
                //   icon: const Icon(Icons.add, size: 18),
                //   label: const Text("Buat Evaluasi Baru"),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: AppColors.primaryBlue,
                //     foregroundColor: Colors.white,
                //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                // ),
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
                      _buildDivisiFilterDropdown(),
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
                        _buildTableHeader("PKWT KE", center: true),
                        _buildTableHeader("AKSI", flex: 1, center: true),
                      ],
                    ),
                  ),

                  // Table Content
                  Consumer<EvaluasiProvider>(
                    builder: (context, provider, _) {
                      final allEvaluasi = provider.getFilteredEvaluasi(
                        timeFilter: _selectedTimeFilter,
                        divisiFilter: _selectedDivisiFilter,
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

  Widget _buildDivisiFilterDropdown() {
    return Consumer<EvaluasiProvider>(
      builder: (context, provider, _) {
        // Build unique divisi list from evaluasi data
        final divisiSet = provider.evaluasiList
            .map((e) => e.employeeDepartemen)
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Divisi: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedDivisiFilter,
                  icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Semua')),
                    ...divisiSet.map((divisi) =>
                      DropdownMenuItem<String?>(value: divisi, child: Text(divisi)),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedDivisiFilter = value;
                    _currentPage = 1;
                  }),
                ),
              ),
            ],
          ),
        );
      },
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
          
          // PKWT Ke
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Ke-${evaluasi.pkwtKe}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 1,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Edit Button
                  Tooltip(
                    message: 'Edit Evaluasi',
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEvaluasiScreen(
                              evaluasi: evaluasi,
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View PDF Button
                  Tooltip(
                    message: 'Lihat PDF',
                    child: InkWell(
                      onTap: () => _showPdfPreview(evaluasi),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteEvaluasi(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Evaluasi berhasil dihapus dari Firestore")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Evaluasi evaluasi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assessment_rounded, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text("Detail Evaluasi")),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: Icon(Icons.close, color: Colors.grey.shade500),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Employee Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluasi.employeeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        evaluasi.employeePosition,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Details
                _buildDetailRow("Periode", evaluasi.periode),
                _buildDetailRow("Tanggal Evaluasi", DateFormat('dd MMMM yyyy').format(evaluasi.tanggalEvaluasi)),
                _buildDetailRow("Evaluator", evaluasi.evaluator),
                _buildDetailRow("Status", evaluasi.status.label),
                
                const SizedBox(height: 16),
                
                // Nilai
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getNilaiColor(evaluasi.nilaiKinerja).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getNilaiColor(evaluasi.nilaiKinerja).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text("Nilai Kinerja", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text(
                              evaluasi.nilaiKinerja,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _getNilaiColor(evaluasi.nilaiKinerja),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Catatan
                if (evaluasi.catatan.isNotEmpty) ...[
                  const Text("Catatan:", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      evaluasi.catatan,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showPdfPreview(evaluasi);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text("Export PDF"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          const Text(": ", style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showPdfPreview(Evaluasi evaluasi) {
    // Generate evaluation data
    Map<int, int?> ratingsNullable = {};
    for (var entry in evaluasi.ratings.entries) {
      ratingsNullable[entry.key] = entry.value;
    }

    final evaluasiData = EvaluasiData(
      namaKaryawan: evaluasi.employeeName,
      posisi: evaluasi.employeePosition,
      departemen: evaluasi.employeeDepartemen.isNotEmpty ? evaluasi.employeeDepartemen : '-',
      lokasiKerja: evaluasi.employeeDepartemen.isNotEmpty ? evaluasi.employeeDepartemen : '-',
      atasanLangsung: evaluasi.atasanLangsung.isNotEmpty ? evaluasi.atasanLangsung : evaluasi.evaluator,
      tanggalMasuk: evaluasi.tanggalMasuk,
      tanggalPkwtBerakhir: evaluasi.tanggalPkwtBerakhir,
      pkwtKe: evaluasi.pkwtKe,
      tanggalEvaluasi: evaluasi.tanggalEvaluasi,
      ratings: ratingsNullable,
      comments: evaluasi.comments,
      recommendation: evaluasi.recommendation,
      perpanjangBulan: evaluasi.perpanjangBulan,
      catatan: evaluasi.catatan,
      namaEvaluator: evaluasi.evaluator,
      sakit: evaluasi.sakit,
      izin: evaluasi.izin,
      terlambat: evaluasi.terlambat,
      mangkir: evaluasi.mangkir,
      signatureBase64: evaluasi.signatureBase64,
      hcgsAdminName: evaluasi.hcgsAdminName.isNotEmpty ? evaluasi.hcgsAdminName : 'Admin HCGS',
      
      // Fixed 4 Signature Slots
      karyawanSignatureBase64: evaluasi.karyawanSignatureBase64,
      karyawanSignatureNama: evaluasi.karyawanSignatureNama,
      karyawanSignatureJabatan: evaluasi.karyawanSignatureJabatan,
      karyawanSignatureStatus: evaluasi.karyawanSignatureStatus,
      
      atasanSignatureBase64: evaluasi.atasanSignatureBase64,
      atasanSignatureNama: evaluasi.atasanSignatureNama,
      atasanSignatureJabatan: evaluasi.atasanSignatureJabatan,
      atasanSignatureStatus: evaluasi.atasanSignatureStatus,
      
      hcgsSignatureBase64: evaluasi.hcgsSignatureBase64,
      hcgsSignatureNama: evaluasi.hcgsSignatureNama,
      hcgsSignatureJabatan: evaluasi.hcgsSignatureJabatan,
      hcgsSignatureStatus: evaluasi.hcgsSignatureStatus,
      
      fungsionalSignatureBase64: evaluasi.fungsionalSignatureBase64,
      fungsionalSignatureNama: evaluasi.fungsionalSignatureNama,
      fungsionalSignatureJabatan: evaluasi.fungsionalSignatureJabatan,
      fungsionalSignatureStatus: evaluasi.fungsionalSignatureStatus,
    );

    ModernPdfPreviewDialog.show(
      context: context,
      evaluasiData: evaluasiData,
      fileName: 'evaluasi_${evaluasi.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }

  void _exportPdfFromEvaluasi(Evaluasi evaluasi) async {
    // This method is now kept as a backup if needed, but not used by default actions
    // as we prefer the in-app preview dialog.
  }
}
