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

class _KontenTambahKaryawanState extends State<KontenTambahKaryawan> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _namaController;
  late TextEditingController _posisiController;
  late TextEditingController _atasanController;
  late TextEditingController _pkwtKeController;
  
  String _departemen = 'IT';
  DateTime? _tglMasuk;
  DateTime? _tglPkwtBerakhir;
  bool _isLoading = false;
  
  // PKWT Upload
  PlatformFile? _selectedPkwtFile;
  bool _uploadingPkwt = false;
  int? _originalPkwtKe; // Track original PKWT Ke to detect changes

  @override
  void initState() {
    super.initState();
    final e = widget.employeeToEdit;
    _namaController = TextEditingController(text: e?.nama ?? '');
    _posisiController = TextEditingController(text: e?.posisi ?? '');
    _atasanController = TextEditingController(text: e?.atasanLangsung ?? '');
    _pkwtKeController = TextEditingController(text: e?.pkwtKe.toString() ?? '1');
    
    if (e != null) {
      _departemen = e.departemen;
      _tglMasuk = e.tglMasuk;
      _tglPkwtBerakhir = e.tglPkwtBerakhir;
      _originalPkwtKe = e.pkwtKe; // Store original value
    }
  }

  final List<String> _departemenList = [
    'IT',
    'Human Resources',
    'Finance',
    'Marketing',
    'Sales',
    'Operations',
    'Product',
    'Legal',
  ];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_tglMasuk == null || _tglPkwtBerakhir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Harap lengkapi semua tanggal'),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      // Validate PKWT upload based on mode
      final currentPkwtKe = int.tryParse(_pkwtKeController.text) ?? 1;
      final isAddMode = widget.employeeToEdit == null;
      final isPkwtKeChanged = !isAddMode && (_originalPkwtKe != currentPkwtKe);
      
      if (isAddMode || isPkwtKeChanged) {
        // PKWT upload is mandatory for:
        // 1. Add mode (new employee)
        // 2. Edit mode with changed PKWT Ke
        if (_selectedPkwtFile == null) {
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

      final newEmployee = Employee(
        id: widget.employeeToEdit?.id ?? const Uuid().v4(), // Use existing ID if editing
        nama: _namaController.text,
        posisi: _posisiController.text,
        departemen: _departemen,
        atasanLangsung: _atasanController.text,
        tglMasuk: _tglMasuk!,
        tglPkwtBerakhir: _tglPkwtBerakhir!,
        pkwtKe: int.tryParse(_pkwtKeController.text) ?? 1,
      );

      if (mounted) {
        try {
          final provider = Provider.of<EmployeeProvider>(context, listen: false);
          if (widget.employeeToEdit != null) {
            await provider.updateEmployee(newEmployee);
          } else {
            await provider.addEmployee(newEmployee);
          }
          
          // Upload PKWT file if selected
          if (_selectedPkwtFile != null && mounted) {
            setState(() => _uploadingPkwt = true);
            try {
              final pkwtKe = int.parse(_pkwtKeController.text);
              final uploadService = PkwtUploadService();
              
              // Upload to Firebase Storage
              final pkwtDocument = await uploadService.uploadPkwtPdf(
                employeeId: newEmployee.id,
                pdfFile: _selectedPkwtFile!,
                pkwtKe: pkwtKe,
              );

              // Save metadata to Firestore
              if (mounted) {
                await Provider.of<PkwtProvider>(context, listen: false)
                    .addPkwtDocument(pkwtDocument);
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
              if (mounted) {
                setState(() => _uploadingPkwt = false);
              }
            }
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(widget.employeeToEdit != null ? 'Data berhasil diperbarui' : 'Data karyawan berhasil disimpan'),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      helpText: label,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
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
    _posisiController.dispose();
    _atasanController.dispose();
    _pkwtKeController.dispose();
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
                      _buildTextField(_posisiController, 'Posisi / Jabatan', Icons.work_rounded),
                      const SizedBox(height: 16),
                      _buildDropdownField(),
                      const SizedBox(height: 16),
                      _buildTextField(_atasanController, 'Atasan Langsung', Icons.supervisor_account_rounded),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Informasi Kontrak PKWT Section
                  _buildSection(
                    title: "Informasi Kontrak PKWT",
                    icon: Icons.description_rounded,
                    children: [
                      _buildDateField('Tanggal Masuk Kerja', _tglMasuk, () => 
                        _pickDate('Pilih Tanggal Masuk', _tglMasuk, (d) => _tglMasuk = d)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDateField('Tanggal PKWT Berakhir', _tglPkwtBerakhir, () => 
                              _pickDate('Pilih Tanggal PKWT Berakhir', _tglPkwtBerakhir, (d) => _tglPkwtBerakhir = d)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPkwtKeField()),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Upload Dokumen PKWT Section (Optional)
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
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

  Widget _buildPkwtKeField() {
    return TextFormField(
      controller: _pkwtKeController,
      keyboardType: TextInputType.number,
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        labelText: 'PKWT Ke-',
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

  Future<void> _pickPkwtFile() async {
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
          _selectedPkwtFile = file;
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

  void _clearPkwtFile() {
    setState(() {
      _selectedPkwtFile = null;
    });
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.upload_file_rounded, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Upload Dokumen PKWT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.employeeToEdit == null
                ? 'Wajib upload dokumen PKWT untuk karyawan baru.'
                : 'Upload dokumen PKWT baru jika PKWT Ke berubah.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          
          // File picker area
          InkWell(
            onTap: _isLoading || _uploadingPkwt ? null : _pickPkwtFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPkwtFile != null ? AppColors.primaryBlue : const Color(0xFFCBD5E1),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: _selectedPkwtFile != null 
                    ? AppColors.primaryBlue.withOpacity(0.02) 
                    : const Color(0xFFF8FAFC),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedPkwtFile != null ? Icons.description : Icons.cloud_upload_outlined,
                      size: 28,
                      color: _selectedPkwtFile != null ? AppColors.primaryBlue : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedPkwtFile != null ? _selectedPkwtFile!.name : 'Pilih File PDF',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedPkwtFile != null ? AppColors.primaryBlue : const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedPkwtFile != null 
                        ? '${(_selectedPkwtFile!.size / 1024 / 1024).toStringAsFixed(2)} MB'
                        : 'Format yang didukung: PDF (Maks. 10MB)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedPkwtFile != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isLoading || _uploadingPkwt ? null : _clearPkwtFile,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Hapus File'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (_uploadingPkwt) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Mengupload dokumen PKWT...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
