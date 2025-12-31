import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/karyawan.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _employeeSubscription;
  String? _userId;

  EmployeeProvider() {
    // Listen to Auth state to handle login/logout
    _auth.authStateChanges().listen((User? user) {
      _employeeSubscription?.cancel();
      
      if (user != null) {
        _userId = user.uid;
        _initRealtimeUpdates(user.uid);
      } else {
        _userId = null;
        _employees = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _initRealtimeUpdates(String userId) {
    _isLoading = true;
    notifyListeners();

    _employeeSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('employees')
        .orderBy('tglMasuk', descending: true)
        .snapshots()
        .listen((snapshot) {
      _employees = snapshot.docs.map((doc) {
        return Employee.fromMap(doc.data());
      }).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error fetching employees: $e");
      _isLoading = false;
      notifyListeners();
    });
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
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees')
          .doc(employee.id)
          .set(employee.toMap());
    } catch (e) {
      debugPrint("Error adding employee: $e");
      rethrow;
    }
  }

  Future<void> addEmployees(List<Employee> employees) async {
    if (_userId == null || employees.isEmpty) return;
    try {
      final batch = _firestore.batch();
      final collection = _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees');

      for (var emp in employees) {
        final docRef = collection.doc(emp.id);
        batch.set(docRef, emp.toMap());
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Error adding employees batch: $e");
      rethrow;
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees')
          .doc(employee.id)
          .update(employee.toMap());
    } catch (e) {
      debugPrint("Error updating employee: $e");
      rethrow;
    }
  }

  Future<void> deleteEmployee(String id) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('employees')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint("Error deleting employee: $e");
    }
  }
}
