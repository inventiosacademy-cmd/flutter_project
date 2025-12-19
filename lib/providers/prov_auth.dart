import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _displayName;
  String? _jobTitle;

  String get displayName => _displayName ?? 'Pengguna';
  String get jobTitle => _jobTitle ?? 'Karyawan';

  bool get isLoggedIn => _auth.currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserInfo(user);
      } else {
        _displayName = 'Pengguna';
        _jobTitle = 'Karyawan';
        notifyListeners();
      }
    });
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
      return null; // Success, no error
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Tidak ditemukan pengguna dengan email tersebut.';
      } else if (e.code == 'wrong-password') {
        return 'Password salah.';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid.';
      } else if (e.code == 'invalid-credential') {
        return 'Email atau password salah.';
      }
      return e.message ?? 'Terjadi kesalahan saat login.';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
