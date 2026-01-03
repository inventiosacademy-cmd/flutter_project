import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pkwt_document.dart';
import '../providers/prov_pkwt.dart';
import '../services/pkwt_upload_service.dart';
import '../theme/warna.dart';

class PkwtUploadDialog extends StatefulWidget {
  final String employeeId;

  const PkwtUploadDialog({
    super.key,
    required this.employeeId,
  });

  @override
  State<PkwtUploadDialog> createState() => _PkwtUploadDialogState();

  static Future<void> show(BuildContext context, String employeeId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PkwtUploadDialog(employeeId: employeeId),
    );
  }
}

class _PkwtUploadDialogState extends State<PkwtUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pkwtKeController = TextEditingController();
  final _uploadService = PkwtUploadService();
  
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _pkwtKeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await _uploadService.pickPdfFile();
      if (file != null) {
        setState(() {
          _selectedFile = file;
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

  Future<void> _uploadFile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih file PDF terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final pkwtKe = int.parse(_pkwtKeController.text);
      
      // Upload to Firebase Storage
      final pkwtDocument = await _uploadService.uploadPkwtPdf(
        employeeId: widget.employeeId,
        pdfFile: _selectedFile!,
        pkwtKe: pkwtKe,
      );

      // Save metadata to Firestore
      if (mounted) {
        await Provider.of<PkwtProvider>(context, listen: false)
            .addPkwtDocument(pkwtDocument);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PKWT berhasil diupload!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.upload_file,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Upload Dokumen PKWT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (!_isUploading)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // PKWT Ke- Input
              TextFormField(
                controller: _pkwtKeController,
                keyboardType: TextInputType.number,
                enabled: !_isUploading,
                decoration: InputDecoration(
                  labelText: 'PKWT Ke-',
                  hintText: 'Contoh: 1, 2, 3',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PKWT Ke- harus diisi';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1) {
                    return 'PKWT Ke- harus angka positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // File Picker
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null
                          ? AppColors.primaryBlue
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFile != null
                        ? AppColors.primaryBlue.withOpacity(0.05)
                        : Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                        size: 48,
                        color: _selectedFile != null
                            ? AppColors.primaryBlue
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile != null
                            ? _selectedFile!.name
                            : 'Klik untuk pilih file PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedFile != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedFile != null
                              ? AppColors.primaryBlue
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_isUploading) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mengupload...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isUploading)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadFile,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
