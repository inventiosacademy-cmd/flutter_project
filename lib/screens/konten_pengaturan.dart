import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/prov_auth.dart' as app_auth;
import '../theme/warna.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  // Local state removed, using AuthProvider

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '-';
    
    // Use data from Provider
    final displayInitial = authProvider.displayName.isNotEmpty 
        ? authProvider.displayName[0].toUpperCase() 
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildProfileCard(context, email, displayInitial, authProvider),
          const SizedBox(height: 24),
          _buildMenuSection(context, authProvider),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pengaturan Akun",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Kelola profil, keamanan, dan informasi aplikasi",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, String email, String initial, app_auth.AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  authProvider.jobTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Edit Icon
          IconButton(
            onPressed: () => _showEditProfileDialog(context, authProvider),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, app_auth.AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader("Akun & Keamanan"),
          _buildActionItem(
            icon: Icons.person_outline_rounded,
            title: "Edit Profil",
            subtitle: "Ubah nama dan jabatan Anda",
            onTap: () => _showEditProfileDialog(context, authProvider),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.lock_reset_outlined,
            title: "Ubah Password",
            subtitle: "Ganti kata sandi akun Anda",
            onTap: () => _resetPassword(context),
          ),
          
          _buildSectionHeader("Notifikasi"),
          _buildActionItem(
            icon: Icons.email_outlined,
            title: "Pengaturan Email Notifikasi",
            subtitle: "Atur email untuk reminder PKWT segera berakhir",
            onTap: () => _showEmailNotificationSettings(context),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.send_outlined,
            title: "Test Kirim Email",
            subtitle: "Kirim email test untuk verifikasi pengaturan",
            onTap: () => _testSendEmail(context),
          ),
          
          _buildSectionHeader("Informasi Aplikasi"),
          _buildActionItem(
            icon: Icons.menu_book_rounded,
            title: "Panduan Aplikasi",
            subtitle: "Cara menggunakan aplikasi HR Dashboard",
            onTap: () => _showFeatureComingSoon(context, "Panduan Aplikasi"),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.privacy_tip_outlined,
            title: "Kebijakan Privasi",
            subtitle: "Bagaimana kami mengelola data Anda",
            onTap: () => _showFeatureComingSoon(context, "Kebijakan Privasi"),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.info_outline_rounded,
            title: "Tentang Aplikasi",
            subtitle: "Versi 1.0.0",
            onTap: () => _showFeatureComingSoon(context, "Info Aplikasi"),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.logout_rounded,
            title: "Keluar Aplikasi",
            subtitle: "Akhiri sesi Anda saat ini",
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, app_auth.AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.displayName);
    final jobController = TextEditingController(text: authProvider.jobTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nama Lengkap",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jobController,
              decoration: const InputDecoration(
                labelText: "Jabatan / Posisi",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              authProvider.updateUserInfo(nameController.text, jobController.text);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profil berhasil diperbarui"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // _updateProfile removed as it is now in AuthProvider

  void _resetPassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      // ... existing code ...
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email reset password telah dikirim"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // ... existing error handling ...
      }
    }
  }
  
  void _showFeatureComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title akan segera tersedia.")),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    // ... existing logout dialog ...
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text("Konfirmasi Keluar"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari aplikasi?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<app_auth.AuthProvider>(context, listen: false).logout();
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  void _showEmailNotificationSettings(BuildContext context) async {
    final emailPengirimController = TextEditingController();
    final passwordAplikasiController = TextEditingController();
    final emailPenerimaController = TextEditingController();
    bool isLoading = true;
    bool isSaving = false;
    bool obscurePassword = true;

    // Load existing settings from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('notifications')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        emailPengirimController.text = data['emailPengirim'] ?? '';
        passwordAplikasiController.text = data['passwordAplikasi'] ?? '';
        emailPenerimaController.text = data['emailPenerima'] ?? '';
      }
      isLoading = false;
    } catch (e) {
      isLoading = false;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.email_outlined, color: AppColors.primaryBlue),
              SizedBox(width: 12),
              Text("Pengaturan Email Notifikasi"),
            ],
          ),
          content: isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Gunakan App Password Gmail, bukan password biasa",
                                style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailPengirimController,
                        decoration: InputDecoration(
                          labelText: "Email Pengirim (Gmail)",
                          hintText: "contoh@gmail.com",
                          prefixIcon: const Icon(Icons.alternate_email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordAplikasiController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: "App Password Gmail",
                          hintText: "xxxx xxxx xxxx xxxx",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          // Open Google App Password page info
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Buka: myaccount.google.com > Security > 2-Step Verification > App Passwords"),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        },
                        child: const Text(
                          "Cara membuat App Password →",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailPenerimaController,
                        decoration: InputDecoration(
                          labelText: "Email Penerima Notifikasi",
                          hintText: "hr@company.com",
                          prefixIcon: const Icon(Icons.mark_email_read_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jadwal Notifikasi:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "• Setiap hari jam 08:00 WIB\n• H-30, H-14, H-7, H-3, H-1 sebelum PKWT berakhir",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (emailPengirimController.text.isEmpty ||
                          passwordAplikasiController.text.isEmpty ||
                          emailPenerimaController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Semua field harus diisi"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isSaving = true);

                      try {
                        await FirebaseFirestore.instance
                            .collection('settings')
                            .doc('notifications')
                            .set({
                          'emailPengirim': emailPengirimController.text.trim(),
                          'passwordAplikasi': passwordAplikasiController.text.trim(),
                          'emailPenerima': emailPenerimaController.text.trim(),
                          'hariSebelumExpired': [30, 14, 7, 3, 1],
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Pengaturan email berhasil disimpan"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Gagal menyimpan: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _testSendEmail(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send_outlined, color: AppColors.primaryBlue),
            SizedBox(width: 12),
            Text("Test Kirim Email"),
          ],
        ),
        content: const Text(
          "Ini akan mengirim email test ke alamat yang sudah dikonfigurasi. "
          "Pastikan pengaturan email sudah benar.\n\n"
          "Lanjutkan?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Kirim Test"),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Mengirim email test..."),
          ],
        ),
      ),
    );

    try {
      // Check if settings exist
      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('notifications')
          .get();

      if (!settingsDoc.exists) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pengaturan email belum dikonfigurasi. Silakan atur terlebih dahulu."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Call the test function URL
      const functionUrl = "https://asia-southeast2-hr-bagong.cloudfunctions.net/testEmailNotification";
      
      final response = await http.get(Uri.parse(functionUrl));
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ ${data['message'] ?? 'Email berhasil dikirim'}"),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("⚠️ ${data['message'] ?? 'Gagal mengirim email'}"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Error: ${data['error'] ?? response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

