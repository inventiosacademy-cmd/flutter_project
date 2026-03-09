import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/prov_evaluasi.dart';
import '../providers/prov_evaluation_upload.dart';
import '../providers/prov_karyawan.dart';
import '../models/evaluasi.dart';
import '../models/karyawan.dart';
import '../theme/warna.dart';
import '../services/pdf_generator.dart';
import '../services/evaluation_upload_service.dart';
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
            Consumer2<EvaluasiProvider, EvaluationUploadProvider>(
              builder: (context, provider, uploadProvider, _) {
                final stats = provider.getStats();
                // Count total manual uploads across all employees
                final totalManual = uploadProvider.totalUploads;
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.assessment_outlined,
                        label: "Total Evaluasi",
                        value: "${(stats['total'] ?? 0) + totalManual}",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.computer_outlined,
                        iconBgColor: const Color(0xFFD1FAE5),
                        iconColor: const Color(0xFF22C55E),
                        label: "Evaluasi Sistem",
                        value: "${stats['total']}",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.upload_file_outlined,
                        iconBgColor: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        label: "Evaluasi Manual",
                        value: "$totalManual",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle_outline,
                        iconBgColor: const Color(0xFFD1FAE5),
                        iconColor: const Color(0xFF22C55E),
                        label: "Selesai (Sistem)",
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
                        _buildTableHeader("TIPE", center: true),
                        _buildTableHeader("STATUS UPLOAD", center: true),
                        _buildTableHeader("AKSI", flex: 1, center: true),
                      ],
                    ),
                  ),

                  // Table Content
                  Consumer2<EvaluasiProvider, EvaluationUploadProvider>(
                    builder: (context, provider, uploadProvider, _) {
                      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

                      // System evaluations filtered
                      final allSistemEvaluasi = provider.getFilteredEvaluasi(
                        timeFilter: _selectedTimeFilter,
                        divisiFilter: _selectedDivisiFilter,
                        searchQuery: _searchQuery,
                      );

                      // All manual uploads (from all employees)
                      final allUploads = uploadProvider.allUploads;
                      // Filter manual uploads by search query
                      final filteredUploads = allUploads.where((u) {
                        final emp = employeeProvider.employees.firstWhere(
                          (e) => e.id == u.employeeId,
                          orElse: () => Employee.empty(),
                        );
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          if (!emp.nama.toLowerCase().contains(q) &&
                              !emp.posisi.toLowerCase().contains(q)) {
                            return false;
                          }
                        }
                        return true;
                      }).toList();

                      // Build unified list
                      final List<Map<String, dynamic>> rows = [];

                      for (final ev in allSistemEvaluasi) {
                        rows.add({
                          'date': ev.tanggalEvaluasi,
                          'name': ev.employeeName,
                          'position': ev.employeePosition,
                          'pkwtKe': ev.pkwtKe,
                          'tipe': 'Sistem',
                          'statusUpload': null,
                          'eval': ev,
                        });
                      }

                      for (final up in filteredUploads) {
                        final emp = employeeProvider.employees.firstWhere(
                          (e) => e.id == up.employeeId,
                          orElse: () => Employee.empty(),
                        );
                        rows.add({
                          'date': up.uploadedAt,
                          'name': emp.nama.isNotEmpty ? emp.nama : up.employeeId,
                          'position': emp.posisi,
                          'pkwtKe': up.pkwtKe,
                          'tipe': 'Manual',
                          'statusUpload': true,
                          'upload': up,
                          'emp': emp,
                        });
                      }

                      // Pending: template printed/downloaded but not yet uploaded
                      for (final pending in uploadProvider.pendingManualEvals) {
                        // Skip if search query doesn't match
                        final emp = employeeProvider.employees.firstWhere(
                          (e) => e.id == pending.employeeId,
                          orElse: () => Employee.empty(),
                        );
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          if (!emp.nama.toLowerCase().contains(q) &&
                              !emp.posisi.toLowerCase().contains(q)) {
                            continue;
                          }
                        }
                        rows.add({
                          'date': DateTime.now(),
                          'name': emp.nama.isNotEmpty ? emp.nama : pending.employeeId,
                          'position': emp.posisi,
                          'pkwtKe': pending.pkwtKe,
                          'tipe': 'Manual',
                          'statusUpload': false,
                          'emp': emp,
                        });
                      }

                      // Sort by date descending
                      rows.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

                      final totalFiltered = rows.length;

                      // Pagination
                      final totalPages = totalFiltered == 0 ? 1 : (totalFiltered / _itemsPerPage).ceil();
                      final startIndex = (_currentPage - 1) * _itemsPerPage;
                      final endIndex = (startIndex + _itemsPerPage).clamp(0, totalFiltered);
                      final pageRows = totalFiltered == 0 ? <Map<String, dynamic>>[] : rows.sublist(startIndex, endIndex);

                      if (rows.isEmpty) {
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
                          ...pageRows.map((row) => _buildUnifiedRow(row, provider, uploadProvider)),
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
    required String label,
    required String value,
    Color? iconBgColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor ?? const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? const Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
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
        // Build unique divisi list from evaluasi data — trim to avoid whitespace dupes
        final divisiSet = provider.evaluasiList
            .map((e) => e.employeeDepartemen.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        // Guard: if current value is no longer in the list, reset to null
        if (_selectedDivisiFilter != null &&
            !divisiSet.contains(_selectedDivisiFilter)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedDivisiFilter = null);
          });
        }

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
                  value: (_selectedDivisiFilter != null &&
                          divisiSet.contains(_selectedDivisiFilter))
                      ? _selectedDivisiFilter
                      : null,
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

  /// Baris unified (sistem + manual)
  Widget _buildUnifiedRow(Map<String, dynamic> row, EvaluasiProvider provider, EvaluationUploadProvider uploadProvider) {
    final isSistem = row['tipe'] == 'Sistem';
    final name = row['name'] as String;
    final position = row['position'] as String;
    final pkwtKe = row['pkwtKe'] as int;
    final date = row['date'] as DateTime;
    final statusUpload = row['statusUpload'] as bool?;

    // Tipe badge
    Widget tipeBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSistem ? const Color(0xFFD1FAE5) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isSistem ? 'Sistem' : 'Manual',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSistem ? const Color(0xFF059669) : const Color(0xFF0284C7),
        ),
      ),
    );

    // Status upload badge
    Widget statusUploadBadge;
    if (isSistem) {
      statusUploadBadge = Text('-', style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
    } else if (statusUpload == true) {
      statusUploadBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Sudah Upload',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
        ),
      );
    } else {
      statusUploadBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Belum Upload',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
        ),
      );
    }

    // Action buttons
    Widget actions;
    if (isSistem) {
      final eval = row['eval'] as Evaluasi;
      actions = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Edit Evaluasi',
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEvaluasiScreen(
                    evaluasi: eval,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, size: 18, color: Color(0xFF22C55E)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Lihat PDF',
            child: InkWell(
              onTap: () => _showPdfPreview(eval),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFFEF4444)),
              ),
            ),
          ),
        ],
      );
    } else {
      final emp = row['emp'] as Employee;
      if (statusUpload == true) {
        // Uploaded: View PDF + Upload Baru
        final up = row['upload'];
        actions = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: 'Lihat PDF',
              child: InkWell(
                onTap: () async {
                  try {
                    await EvaluationUploadService().downloadPdf(up.fileUrl as String, up.fileName as String);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error membuka PDF: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.visibility, size: 18, color: Color(0xFF0284C7)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Upload Baru',
              child: InkWell(
                onTap: () => _showUploadDialog(emp, pkwtKe),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.upload_file, size: 18, color: Color(0xFF0EA5E9)),
                ),
              ),
            ),
          ],
        );
      } else {
        // Pending: template dicetak, belum ada file upload
        actions = Tooltip(
          message: 'Upload Evaluasi',
          child: InkWell(
            onTap: () => _showUploadDialog(emp, pkwtKe),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, size: 16, color: Color(0xFFF97316)),
                  SizedBox(width: 6),
                  Text(
                    'Upload',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF97316)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
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
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                if (position.isNotEmpty)
                  Text(position, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          // Tanggal
          Expanded(
            child: Text(
              DateFormat('dd MMM yyyy').format(date),
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
                  'Ke-$pkwtKe',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                ),
              ),
            ),
          ),
          // Tipe
          Expanded(child: Center(child: tipeBadge)),
          // Status Upload
          Expanded(child: Center(child: statusUploadBadge)),
          // Actions
          Expanded(
            child: Center(child: actions),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(Employee emp, int pkwtKe) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RiwayatUploadDialog(employee: emp, pkwtKe: pkwtKe),
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

/// Dialog upload evaluasi manual dari halaman Riwayat Evaluasi.
/// pkwtKe serta nama karyawan sudah ter-preset di header.
class _RiwayatUploadDialog extends StatefulWidget {
  final Employee employee;
  final int pkwtKe;

  const _RiwayatUploadDialog({required this.employee, required this.pkwtKe});

  @override
  State<_RiwayatUploadDialog> createState() => _RiwayatUploadDialogState();
}

class _RiwayatUploadDialogState extends State<_RiwayatUploadDialog> {
  final _uploadService = EvaluationUploadService();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final file = await _uploadService.pickPdfFile();
      if (file != null && mounted) setState(() => _selectedFile = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file PDF terlebih dahulu'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final evaluationUpload = await _uploadService.uploadEvaluationPdf(
        employeeId: widget.employee.id,
        pdfFile: _selectedFile!,
        pkwtKe: widget.pkwtKe,
      );
      if (mounted) {
        await Provider.of<EvaluationUploadProvider>(context, listen: false)
            .addEvaluationUpload(evaluationUpload);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluasi manual berhasil disimpan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.upload_file, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Evaluasi Manual',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      if (widget.employee.nama.isNotEmpty)
                        Text(
                          '${widget.employee.nama} · PKWT Ke-${widget.pkwtKe}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                if (!_isUploading)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // File picker area
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null ? AppColors.primaryBlue : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null
                      ? AppColors.primaryBlue.withOpacity(0.04)
                      : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                      size: 48,
                      color: _selectedFile != null ? AppColors.primaryBlue : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.name
                          : 'Klik untuk pilih file PDF evaluasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedFile != null ? AppColors.primaryBlue : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Menyimpan...', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isUploading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadFile,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isUploading ? 'Menyimpan...' : 'Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
