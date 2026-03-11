import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/karyawan.dart';

import '../utils/error_helper.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  EmployeeProvider() {
    // Listen to Auth state to handle login/logout
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        _loadEmployees(user.uid);
      } else {
        _userId = null;
        _employees = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadEmployees(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('employees')
          .orderBy('tglMasuk', descending: true)
          .get();

      _employees = snapshot.docs.map((doc) {
        return Employee.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload data dari server manual (jika dibutuhkan)
  Future<void> refreshEmployees() async {
    if (_userId != null) {
      await _loadEmployees(_userId!);
    }
  }

  List<Employee> get employees => [..._employees];
  bool get isLoading => _isLoading;

  List<Employee> get expiringContracts {
    return _employees.where((e) {
      final days = e.hariMenujuExpired;
      return days >= 0 && days < 30;
    }).toList();
  }

  Future<void> addEmployee(Employee employee) async {
    if (_userId == null) {
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    }
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees')
          .doc(employee.id)
          .set(employee.toMap());

      // Tulis ke RAM agar langsung refresh
      _employees.insert(0, employee);
      notifyListeners();

    } catch (e) {
      debugPrint("Error adding employee: $e");
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'Karyawan'));
    }
  }

  Future<void> addEmployees(List<Employee> employees) async {
    debugPrint("addEmployees called with ${employees.length} employees");
    debugPrint("Current userId: $_userId");
    
    if (_userId == null || employees.isEmpty) {
      if (_userId == null) {
        throw Exception('Sesi login telah berakhir. Silakan login kembali.');
      }
      debugPrint("Employee list is empty, nothing to import");
      return;
    }
    
    try {
      debugPrint("Creating batch operation...");
      final batch = _firestore.batch();
      final collection = _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees');

      for (var emp in employees) {
        debugPrint("Adding employee to batch: ${emp.nama} (ID: ${emp.id})");
        final docRef = collection.doc(emp.id);
        batch.set(docRef, emp.toMap());
      }

      debugPrint("Committing batch to Firestore...");
      await batch.commit();
      debugPrint("Batch committed successfully!");

      // Tulis ke RAM untuk semuanya agar langsung refresh
      _employees.addAll(employees);
      // Sort ulang berdasar tanggal masuk
      _employees.sort((a, b) => b.tglMasuk.compareTo(a.tglMasuk));
      notifyListeners();

    } catch (e) {
      debugPrint("Error adding employees batch: $e");
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'Karyawan'));
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    if (_userId == null) {
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    }
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees')
          .doc(employee.id)
          .update(employee.toMap());

      // Tulis (Update) ke RAM agar langsung refresh
      final index = _employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _employees[index] = employee;
        notifyListeners();
      }

    } catch (e) {
      debugPrint("Error updating employee: $e");
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'Karyawan'));
    }
  }

  Future<void> deleteEmployee(String id) async {
    if (_userId == null) {
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    }
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees')
          .doc(id)
          .delete();

      // Hapus dari RAM agar langsung refresh
      _employees.removeWhere((e) => e.id == id);
      notifyListeners();

    } catch (e) {
      debugPrint("Error deleting employee: $e");
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'Karyawan'));
    }
  }
}
