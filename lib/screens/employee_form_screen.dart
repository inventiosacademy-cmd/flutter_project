import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../theme/app_colors.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _namaController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _ktpController = TextEditingController();
  final _npwpController = TextEditingController();
  
  String _jenisKelamin = 'Laki-laki';
  DateTime? _tglLahir;
  DateTime? _tglMulai;
  DateTime? _tglSelesai;
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_tglLahir == null || _tglMulai == null || _tglSelesai == null) {
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

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      final newEmployee = Employee(
        id: const Uuid().v4(),
        nama: _namaController.text,
        jenisKelamin: _jenisKelamin,
        tempatLahir: _tempatLahirController.text,
        tglLahir: _tglLahir!,
        alamat: _alamatController.text,
        noHp: _noHpController.text,
        email: _emailController.text,
        ktp: _ktpController.text,
        npwp: _npwpController.text,
        tglMulai: _tglMulai!,
        tglSelesai: _tglSelesai!,
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
        
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickDate(BuildContext context, String label, DateTime? initial, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1950),
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
      setState(() {
        onPicked(picked);
      });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tempatLahirController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _ktpController.dispose();
    _npwpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah Karyawan",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Info Section
              _buildSectionHeader("Informasi Pribadi", Icons.person_rounded),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama Lengkap',
                      icon: Icons.badge_rounded,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDropdownField(),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _tempatLahirController,
                            label: 'Tempat Lahir',
                            icon: Icons.location_city_rounded,
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Tanggal Lahir',
                            value: _tglLahir,
                            onTap: () => _pickDate(context, 'Pilih Tanggal Lahir', _tglLahir, (d) => _tglLahir = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _alamatController,
                      label: 'Alamat Rumah',
                      icon: Icons.home_rounded,
                      maxLines: 2,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contact Info Section
              _buildSectionHeader("Informasi Kontak", Icons.contact_phone_rounded),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _noHpController,
                      label: 'Nomor HP',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Document Info Section
              _buildSectionHeader("Dokumen Identitas", Icons.folder_rounded),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _ktpController,
                      label: 'Nomor KTP',
                      icon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _npwpController,
                      label: 'NPWP',
                      icon: Icons.receipt_long_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contract Info Section
              _buildSectionHeader("Informasi Kontrak", Icons.description_rounded),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'Tanggal Mulai',
                        value: _tglMulai,
                        onTap: () => _pickDate(context, 'Pilih Tanggal Mulai', _tglMulai, (d) => _tglMulai = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(
                        label: 'Tanggal Selesai',
                        value: _tglSelesai,
                        onTap: () => _pickDate(context, 'Pilih Tanggal Selesai', _tglSelesai, (d) => _tglSelesai = d),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "SIMPAN DATA",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _jenisKelamin,
      items: ['Laki-laki', 'Perempuan']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _jenisKelamin = v!),
      decoration: InputDecoration(
        labelText: 'Jenis Kelamin',
        prefixIcon: const Icon(Icons.wc_rounded),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Text(
          value == null
              ? 'Pilih Tanggal'
              : DateFormat('dd/MM/yyyy').format(value),
          style: TextStyle(
            color: value == null ? Colors.grey.shade400 : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
