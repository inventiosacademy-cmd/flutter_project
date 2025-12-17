import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/karyawan.dart';
import '../providers/prov_karyawan.dart';
import '../theme/warna.dart';

class KontenTambahKaryawan extends StatefulWidget {
  final VoidCallback onBack;
  
  const KontenTambahKaryawan({super.key, required this.onBack});

  @override
  State<KontenTambahKaryawan> createState() => _KontenTambahKaryawanState();
}

class _KontenTambahKaryawanState extends State<KontenTambahKaryawan> {
  final _formKey = GlobalKey<FormState>();
  
  final _namaController = TextEditingController();
  final _posisiController = TextEditingController();
  final _atasanController = TextEditingController();
  final _pkwtKeController = TextEditingController(text: '1');
  
  
  String _departemen = 'IT';
  DateTime? _tglMasuk;
  DateTime? _tglPkwtBerakhir;
  bool _isLoading = false;

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

      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));

      final newEmployee = Employee(
        id: const Uuid().v4(),
        nama: _namaController.text,
        posisi: _posisiController.text,
        departemen: _departemen,
        atasanLangsung: _atasanController.text,
        tglMasuk: _tglMasuk!,
        tglPkwtBerakhir: _tglPkwtBerakhir!,
        pkwtKe: int.tryParse(_pkwtKeController.text) ?? 1,
      );

      if (mounted) {
        Provider.of<EmployeeProvider>(context, listen: false).addEmployee(newEmployee);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Data karyawan berhasil disimpan'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        widget.onBack();
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tambah Karyawan Baru",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Isi data karyawan dan informasi kontrak PKWT",
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
                    title: "Data Karyawan",
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text("Simpan Data", style: TextStyle(fontWeight: FontWeight.w600)),
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
}
