import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_tglLahir == null || _tglMulai == null || _tglSelesai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap lengkapi semua tanggal')),
        );
        return;
      }

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

      Provider.of<EmployeeProvider>(context, listen: false).addEmployee(newEmployee);
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate(BuildContext context, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Data Karyawan")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                value: _jenisKelamin,
                items: ['Laki-laki', 'Perempuan'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _jenisKelamin = v!),
                decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempatLahirController,
                      decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, (d) => _tglLahir = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
                        child: Text(_tglLahir == null ? 'Pilih Tgl' : DateFormat('dd/MM/yyyy').format(_tglLahir!)),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat Rumah'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _noHpController,
                decoration: const InputDecoration(labelText: 'No HP'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _ktpController,
                decoration: const InputDecoration(labelText: 'Nomor KTP'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _npwpController,
                decoration: const InputDecoration(labelText: 'NPWP'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              const Text("Informasi Kontrak", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, (d) => _tglMulai = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tgl Mulai'),
                        child: Text(_tglMulai == null ? 'Pilih Tgl' : DateFormat('dd/MM/yyyy').format(_tglMulai!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, (d) => _tglSelesai = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tgl Selesai'),
                        child: Text(_tglSelesai == null ? 'Pilih Tgl' : DateFormat('dd/MM/yyyy').format(_tglSelesai!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("SIMPAN DATA"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
