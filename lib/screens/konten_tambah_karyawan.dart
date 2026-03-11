import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/karyawan.dart';
import '../providers/prov_karyawan.dart';
import '../providers/prov_pkwt.dart';
import '../services/pkwt_upload_service.dart';
import '../theme/warna.dart';

class KontenTambahKaryawan extends StatefulWidget {
  final VoidCallback onBack;
  final Employee? employeeToEdit;
  
  const KontenTambahKaryawan({super.key, required this.onBack, this.employeeToEdit});

  @override
  State<KontenTambahKaryawan> createState() => _KontenTambahKaryawanState();
}

/// Helper class to hold one PKWT entry
class _PkwtEntry {
  int pkwtKe;
  DateTime? tglMasuk;
  DateTime? tglBerakhir;
  PlatformFile? file;
  final TextEditingController pkwtKeController;

  _PkwtEntry({
    required this.pkwtKe,
    this.tglMasuk,
    this.tglBerakhir,
    this.file,
  }) : pkwtKeController = TextEditingController(text: pkwtKe.toString());

  void dispose() => pkwtKeController.dispose();
  int get currentKe => int.tryParse(pkwtKeController.text) ?? pkwtKe;
}

class _KontenTambahKaryawanState extends State<KontenTambahKaryawan> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _idController;
  late TextEditingController _posisiController;
  late TextEditingController _atasanController;

  String _departemen = 'HCGS';
  bool _isLoading = false;

  // PKWT Upload — list of entries (each entry = pkwtKe + dates + PDF)
  List<_PkwtEntry> _pkwtEntries = [];
  bool _uploadingPkwt = false;
  int? _originalPkwtKe; // Track original PKWT Ke to detect changes

  @override
  void initState() {
    super.initState();
    final e = widget.employeeToEdit;
    _namaController = TextEditingController(text: e?.nama ?? '');
    _idController = TextEditingController(text: e?.id ?? '');
    _posisiController = TextEditingController(text: e?.posisi ?? '');
    _atasanController = TextEditingController(text: e?.atasanLangsung ?? '');

    if (e != null) {
      _departemen = e.departemen;
      _originalPkwtKe = e.pkwtKe;
      // Guard: if employee's departemen is not in the list, add it
      if (_departemen.isNotEmpty && !_departemenList.contains(_departemen)) {
        _departemenList.add(_departemen);
      }
    }

    // Pre-populate first PKWT entry with existing data if editing
    _pkwtEntries = [
      _PkwtEntry(
        pkwtKe: e?.pkwtKe ?? 1,
        tglMasuk: e?.tglMasuk,
        tglBerakhir: e?.tglPkwtBerakhir,
      ),
    ];
  }

  final List<String> _departemenList = [
    'HCGS',
    'SCM',
    'FAT',
    'OPERASIONAL',
    'PLANT',
    'TDC',
    'IT',
  ];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Validate: every entry must have both dates
      for (int i = 0; i < _pkwtEntries.length; i++) {
        final entry = _pkwtEntries[i];
        if (entry.tglMasuk == null || entry.tglBerakhir == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('PKWT Ke-${entry.pkwtKe}: harap lengkapi semua tanggal'),
                ],
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          return;
        }
      }

      // Validate PKWT upload based on mode
      final isAddMode = widget.employeeToEdit == null;
      final currentPkwtKe = _pkwtEntries.first.currentKe;
      final isPkwtKeChanged = !isAddMode && (_originalPkwtKe != currentPkwtKe);

      if (isAddMode || isPkwtKeChanged) {
        final hasAnyFile = _pkwtEntries.any((e) => e.file != null);
        if (!hasAnyFile) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(isAddMode
                      ? 'Dokumen PKWT wajib diupload'
                      : 'Upload dokumen PKWT baru karena PKWT Ke berubah'),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          return;
        }
      }

      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));

      // Use the FIRST entry's dates as the Employee's primary contract dates
      final firstEntry = _pkwtEntries.first;
      final newEmployeeId = _idController.text.trim();
          
      final newEmployee = Employee(
        id: newEmployeeId,
        nama: _namaController.text,
        posisi: _posisiController.text,
        departemen: _departemen,
        atasanLangsung: _atasanController.text,
        tglMasuk: firstEntry.tglMasuk!,
        tglPkwtBerakhir: firstEntry.tglBerakhir!,
        pkwtKe: firstEntry.currentKe,
      );

      if (mounted) {
        try {
          final provider = Provider.of<EmployeeProvider>(context, listen: false);
          if (widget.employeeToEdit != null) {
            await provider.updateEmployee(newEmployee);
          } else {
            await provider.addEmployee(newEmployee);
          }

          // Upload all PKWT files that have a file selected
          final entriesWithFile = _pkwtEntries.where((e) => e.file != null).toList();
          if (entriesWithFile.isNotEmpty && mounted) {
            setState(() => _uploadingPkwt = true);
            try {
              final uploadService = PkwtUploadService();
              for (final entry in entriesWithFile) {
                final pkwtDocument = await uploadService.uploadPkwtPdf(
                  employeeId: newEmployee.id,
                  pdfFile: entry.file!,
                  pkwtKe: entry.pkwtKe,
                );
                if (mounted) {
                  await Provider.of<PkwtProvider>(context, listen: false)
                      .addPkwtDocument(pkwtDocument);
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data karyawan tersimpan, tapi gagal upload PKWT: $e'),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            } finally {
              if (mounted) setState(() => _uploadingPkwt = false);
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(widget.employeeToEdit != null
                        ? 'Data berhasil diperbarui'
                        : 'Data karyawan berhasil disimpan'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            widget.onBack();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan data: $e'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            setState(() => _isLoading = false);
          }
        }
      }
    }
  }

  Future<void> _pickDate(String label, DateTime? initial, Function(DateTime) onPicked) async {
    final DateTime now = DateTime.now();
    DateTime tempDate = initial ?? now;
    
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            // Function to get days in month
            int getDaysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
            // Function to get first day offset (0 = Sunday, 1 = Monday, etc.)
            int getFirstDayOffset(int year, int month) => DateTime(year, month, 1).weekday % 7;
            
            final int daysInMonth = getDaysInMonth(tempDate.year, tempDate.month);
            final int firstDayOffset = getFirstDayOffset(tempDate.year, tempDate.month);
            
            final List<String> months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            
            final List<int> years = List.generate(41, (index) => 2000 + index); // 2000 to 2040

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select Date",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B), // Dark slate
                                ),
                              ),
                              SizedBox(height: 4),
                              // Removing "Choose a day for your schedule" as requested
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                            visualDensity: VisualDensity.compact,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    
                    // Month & Year Selectors
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          // Month Dropdown
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "MONTH",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: tempDate.month,
                                      icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF94A3B8)),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                      items: List.generate(12, (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text(months[i]),
                                      )),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setStateBuilder(() {
                                            tempDate = DateTime(tempDate.year, val, tempDate.day > getDaysInMonth(tempDate.year, val) ? getDaysInMonth(tempDate.year, val) : tempDate.day);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Year Dropdown
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "YEAR",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: tempDate.year,
                                      icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF94A3B8)),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                      items: years.map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y.toString()),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setStateBuilder(() {
                                            tempDate = DateTime(val, tempDate.month, tempDate.day > getDaysInMonth(val, tempDate.month) ? getDaysInMonth(val, tempDate.month) : tempDate.day);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Calendar Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Days of week
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'].map((day) => 
                              SizedBox(
                                width: 32,
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              )
                            ).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Dates
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 42, // 6 rows of 7 days
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              // Previous month days
                              if (index < firstDayOffset) {
                                final prevMonthDays = getDaysInMonth(
                                  tempDate.month == 1 ? tempDate.year - 1 : tempDate.year,
                                  tempDate.month == 1 ? 12 : tempDate.month - 1
                                );
                                final day = prevMonthDays - firstDayOffset + index + 1;
                                return Center(
                                  child: Text(
                                    day.toString(),
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                                  ),
                                );
                              }
                              
                              // Current month days
                              final day = index - firstDayOffset + 1;
                              if (day <= daysInMonth) {
                                final isSelected = tempDate.day == day;
                                return InkWell(
                                  onTap: () {
                                    setStateBuilder(() {
                                      tempDate = DateTime(tempDate.year, tempDate.month, day);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            color: const Color(0xFF0EA5E9), // Blue accent instead of orange
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0EA5E9).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Center(
                                      child: Text(
                                        day.toString(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : const Color(0xFF334155),
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              // Next month days
                              return const SizedBox.shrink(); // Hide extra rows if empty
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    
                    // Footer Buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, tempDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9), // Blue accent instead of orange
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Apply Date", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _idController.dispose();
    _posisiController.dispose();
    _atasanController.dispose();
    for (final e in _pkwtEntries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employeeToEdit != null ? "Edit Data Karyawan" : "Tambah Karyawan Baru",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.employeeToEdit != null ? "Perbarui informasi data karyawan" : "Isi data karyawan dan informasi kontrak PKWT",
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Form Content
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Karyawan Section
                  _buildSection(
                    title: "Dashboard",
                    icon: Icons.person_rounded,
                    children: [
                      _buildTextField(_namaController, 'Nama Lengkap', Icons.badge_rounded),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _idController, 
                        'ID Karyawan', 
                        Icons.numbers_rounded,
                        isRequired: true,
                        readOnly: widget.employeeToEdit != null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_posisiController, 'Posisi / Jabatan', Icons.work_rounded),
                      const SizedBox(height: 16),
                      _buildDropdownField(),
                      const SizedBox(height: 16),
                      _buildTextField(_atasanController, 'Atasan Langsung', Icons.supervisor_account_rounded),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Kontrak PKWT Section (tanggal + upload per entri)
                  _buildPkwtUploadSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(widget.employeeToEdit != null ? "Simpan Perubahan" : "Simpan Data", style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isRequired = true, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: (v) => isRequired && v!.isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _departemen,
      items: _departemenList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => _departemen = v!),
      decoration: InputDecoration(
        labelText: 'Departemen',
        prefixIcon: const Icon(Icons.business_rounded, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          value == null ? 'Pilih Tanggal' : DateFormat('dd MMMM yyyy').format(value),
          style: TextStyle(color: value == null ? Colors.grey.shade400 : const Color(0xFF1E293B)),
        ),
      ),
    );
  }

  Future<void> _pickPkwtFileForEntry(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file terlalu besar. Maksimal 10MB'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _pkwtEntries[index].file = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearPkwtFileForEntry(int index) {
    setState(() {
      _pkwtEntries[index].file = null;
    });
  }

  void _addPkwtEntry() {
    setState(() {
      // Use stored pkwtKe int (not the text controller) to avoid stale-state crash
      final nextKe = _pkwtEntries.isEmpty
          ? 1
          : _pkwtEntries.map((e) => e.pkwtKe).reduce((a, b) => a > b ? a : b) + 1;
      _pkwtEntries.add(_PkwtEntry(pkwtKe: nextKe));
    });
  }

  void _removePkwtEntry(int index) {
    final entry = _pkwtEntries[index];
    setState(() {
      _pkwtEntries.removeAt(index);
    });
    entry.dispose();
  }

  Widget _buildPkwtUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_rounded, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Kontrak PKWT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Entry list ──────────────────────────────────────────────
          ..._pkwtEntries.asMap().entries.map((mapEntry) {
            final idx = mapEntry.key;
            final entry = mapEntry.value;
            final hasFile = entry.file != null;
            final isFirst = idx == 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Divider between entries
                if (!isFirst) ...[
                  const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
                ],

                // Remove button (only when >1 entry)
                if (_pkwtEntries.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _isLoading || _uploadingPkwt ? null : () => _removePkwtEntry(idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text('Hapus', style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_pkwtEntries.length > 1) const SizedBox(height: 8),

                // ── Row: Tanggal Masuk | Tanggal Berakhir ─────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildLabeledDateField(
                        label: 'Tanggal Masuk Kerja',
                        value: entry.tglMasuk,
                        onTap: () => _pickDate(
                          'Tanggal Masuk',
                          entry.tglMasuk,
                          (d) => setState(() => entry.tglMasuk = d),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLabeledDateField(
                        label: 'Tanggal PKWT Berakhir',
                        value: entry.tglBerakhir,
                        onTap: () => _pickDate(
                          'Tanggal PKWT Berakhir',
                          entry.tglBerakhir,
                          (d) => setState(() => entry.tglBerakhir = d),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── PKWT Ke- text input ───────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PKWT Ke-',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: entry.pkwtKeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Masukkan urutan PKWT',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Upload File PKWT ──────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPLOAD FILE PKWT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasFile)
                      // File selected state
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryBlue, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.file!.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(entry.file!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Re-pick button
                                InkWell(
                                  onTap: _isLoading || _uploadingPkwt ? null : () => _pickPkwtFileForEntry(idx),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.refresh_rounded, size: 18, color: Colors.grey.shade500),
                                  ),
                                ),
                                // Remove file button
                                InkWell(
                                  onTap: _isLoading || _uploadingPkwt ? null : () => _clearPkwtFileForEntry(idx),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      // Empty state — dashed upload box
                      InkWell(
                        onTap: _isLoading || _uploadingPkwt ? null : () => _pickPkwtFileForEntry(idx),
                        borderRadius: BorderRadius.circular(10),
                        child: _DashedBorder(
                          borderRadius: 10,
                          color: const Color(0xFFCBD5E1),
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.primaryBlue),
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                      children: [
                                        const TextSpan(text: 'Klik untuk pilih file'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Format PDF maksimal 10MB',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),

          const SizedBox(height: 20),

          // ── Upload progress ──────────────────────────────────────────
          if (_uploadingPkwt) ...[
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Mengupload dokumen PKWT...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Tambah PKWT Lainnya button ───────────────────────────────
          GestureDetector(
            onTap: _isLoading || _uploadingPkwt ? null : _addPkwtEntry,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isLoading || _uploadingPkwt
                      ? Colors.grey.shade300
                      : AppColors.primaryBlue.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primaryBlue.withOpacity(0.03),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: _isLoading || _uploadingPkwt
                        ? Colors.grey.shade400
                        : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tambah PKWT Lainnya',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isLoading || _uploadingPkwt
                          ? Colors.grey.shade400
                          : AppColors.primaryBlue,
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

  Widget _buildLabeledDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? 'mm/dd/yyyy'
                        : DateFormat('dd/MM/yyyy').format(value),
                    style: TextStyle(
                      fontSize: 13,
                      color: value == null ? Colors.grey.shade400 : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeStepButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(6),
          color: onTap == null ? Colors.grey.shade100 : Colors.white,
        ),
        child: Icon(icon, size: 14,
            color: onTap == null ? Colors.grey.shade400 : const Color(0xFF334155)),
      ),
    );
  }
}

/// Custom dashed-border container for upload area
class _DashedBorder extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  const _DashedBorder({
    required this.child,
    required this.borderRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(borderRadius: borderRadius, color: color),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  _DashedBorderPainter({required this.borderRadius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final r = borderRadius;
    final rect = Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next.toDouble()),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
