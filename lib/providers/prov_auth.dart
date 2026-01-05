import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../services/activity_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Create storage with specific options for Windows (optional)
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  String? _displayName;
  String? _jobTitle;

  String get displayName => _displayName ?? 'Pengguna';
  String get jobTitle => _jobTitle ?? 'Karyawan';

  bool get isLoggedIn => _auth.currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserInfo(user);
        _persistToken(user); // Simpan token sesi secara aman
        startIdleTimer(); // START SESSION TIMER
      } else {
        _displayName = 'Pengguna';
        _jobTitle = 'Karyawan';
        _clearToken(); // Hapus token saat logout
        _cancelIdleTimer(); // STOP TIMER
        notifyListeners();
      }
    });
  }

  // --- IDLE TIMER LOGIC (6 HOURS) ---
  Timer? _idleTimer;
  static const int _idleDurationSeconds = 21600; // 6 Hours

  void startIdleTimer() {
    _cancelIdleTimer();
    _idleTimer = Timer(const Duration(seconds: _idleDurationSeconds), () {
      debugPrint("⏰ Idle Timeout Reached (6 Hours). Logging out...");
      // Auto logout on timeout
      logout();
    });
  }
  
  void resetIdleTimer() {
    // Only reset if logged in
    if (_auth.currentUser != null) {
      startIdleTimer();
    }
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }


  // Simpan ID Token/Session ke Secure Storage (Credential Manager Windows)
  Future<void> _persistToken(User user) async {
    try {
      String? token = await user.getIdToken();
      if (token != null) {
        await _storage.write(key: 'auth_token', value: token);
      }
    } catch (e) {
      debugPrint("Secure storage error: $e");
    }
  }

  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
    } catch (e) {
      debugPrint("Secure storage delete error: $e");
    }
  }

  Future<void> _fetchUserInfo(User user) async {
    _displayName = user.displayName ?? user.email?.split('@')[0] ?? 'Pengguna';
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['displayName'] != null) {
          _displayName = data['displayName'].toString();
        }
        if (data['jobTitle'] != null) {
          _jobTitle = data['jobTitle'].toString();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user info: $e");
    }
  }

  Future<void> updateUserInfo(String name, String job) async {
    _displayName = name;
    _jobTitle = job;
    notifyListeners();

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': name,
          'jobTitle': job,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating user info: $e");
      }
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return 'Email dan password harus diisi.';
      }
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // LOG ACTIVITY: Login Success
      await ActivityService().logLogin();
      
      return null; // Success, no error
    } on FirebaseAuthException catch (e) {
      // SECURITY: Cegah User Enumeration dengan pesan error generik
      if (e.code == 'user-not-found' || 
          e.code == 'wrong-password' || 
          e.code == 'invalid-credential') {
        return 'Email atau password salah.';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid.';
      }
      return e.message ?? 'Terjadi kesalahan saat login.';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> logout() async {
    // LOG ACTIVITY: Logout
    if (_auth.currentUser != null) {
       await ActivityService().logLogout();
    }
    
    _cancelIdleTimer();
    await _auth.signOut();
  }
}
