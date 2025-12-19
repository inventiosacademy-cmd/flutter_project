import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/karyawan.dart';
import '../providers/prov_karyawan.dart';
import '../theme/warna.dart';

class KontenDetailKaryawan extends StatefulWidget {
  final Employee employee;
  final VoidCallback onBack;

  const KontenDetailKaryawan({
    super.key,
    required this.employee,
    required this.onBack,
  });

  @override
  State<KontenDetailKaryawan> createState() => _KontenDetailKaryawanState();
}

class _KontenDetailKaryawanState extends State<KontenDetailKaryawan> {
  int _selectedTab = 0; // 0 = Personal Profile, 1 = Evaluasi

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb / Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          color: Colors.white,
          width: double.infinity,
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: "Kembali",
              ),
              const SizedBox(width: 8),
              const Text(
                "Detail Karyawan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        
        // Main Content Area
        Expanded(
          child: Container(
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel - Profile Card
                Container(
                  width: 340,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.employee.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 28),
                      Consumer<EmployeeProvider>(
                        builder: (context, provider, _) {
                          final index = provider.employees.indexWhere((e) => e.id == widget.employee.id);
                          final displayId = index != -1 
                              ? "EMP-${DateTime.now().year}-${(index + 1).toString().padLeft(3, '0')}"
                              : widget.employee.id;
                          return _buildLeftPanelItem("ID Karyawan", displayId);
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildLeftPanelItem("Masa Kerja", widget.employee.masaKerja),
                    ],
                  ),
                ),
                
                // Right Panel - Tabs & Information
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            children: [
                              _buildTab("Personal Profile", 0),
                              _buildTab("Evaluasi", 1),
                            ],
                          ),
                        ),
                        
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(48),
                            child: _selectedTab == 0
                                ? _buildProfileContent()
                                : _buildEvaluasiContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanelItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          border: isActive
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryBlue : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Employment Details - Vertical Layout
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem("Departemen", widget.employee.departemen),
            const SizedBox(height: 24),
            _buildDetailItem("Posisi", widget.employee.posisi),
            const SizedBox(height: 24),
            _buildDetailItem("Atasan Langsung", widget.employee.atasanLangsung),
            const SizedBox(height: 24),
            _buildDetailItem("Tanggal Masuk", DateFormat('dd MMMM yyyy').format(widget.employee.tglMasuk)),
            const SizedBox(height: 24),
            _buildDetailItem("Akhir Kontrak", DateFormat('dd MMMM yyyy').format(widget.employee.tglPkwtBerakhir)),
            const SizedBox(height: 24),
            _buildDetailItem("Status PKWT", "PKWT Ke-${widget.employee.pkwtKe}"),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluasiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.assessment_outlined,
                size: 20,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Riwayat Evaluasi Karyawan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Timeline design for evaluations
        _buildEvaluationTimeline(),
      ],
    );
  }

  Widget _buildEvaluationTimeline() {
    // Sample evaluation data
    final evaluations = [
      _EvaluationItem(
        date: DateTime(2024, 12, 1),
        title: "Evaluasi Kinerja Q4 2024",
        score: "A",
        notes: "Kinerja sangat baik, mencapai target penjualan 120%",
      ),
      _EvaluationItem(
        date: DateTime(2024, 9, 1),
        title: "Evaluasi Kinerja Q3 2024",
        score: "A-",
        notes: "Kinerja baik, perlu peningkatan di area komunikasi tim",
      ),
      _EvaluationItem(
        date: DateTime(2024, 6, 1),
        title: "Evaluasi Kinerja Q2 2024",
        score: "B+",
        notes: "Kinerja cukup baik, adaptasi dengan sistem baru",
      ),
    ];

    if (evaluations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "Belum ada data evaluasi",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: evaluations.map((eval) {
        return _buildEvaluationCard(eval);
      }).toList(),
    );
  }

  Widget _buildEvaluationCard(_EvaluationItem evaluation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Badge
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _getScoreColor(evaluation.score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getScoreColor(evaluation.score).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                evaluation.score,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(evaluation.score),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        evaluation.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(evaluation.date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  evaluation.notes,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(String score) {
    if (score.startsWith('A')) {
      return const Color(0xFF059669);
    } else if (score.startsWith('B')) {
      return AppColors.primaryBlue;
    } else if (score.startsWith('C')) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFFEF4444);
    }
  }
}

class _EvaluationItem {
  final DateTime date;
  final String title;
  final String score;
  final String notes;

  _EvaluationItem({
    required this.date,
    required this.title,
    required this.score,
    required this.notes,
  });
}
