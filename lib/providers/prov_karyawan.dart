import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/karyawan.dart';
import '../services/activity_service.dart';
import '../utils/error_helper.dart';

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
          
      // LOG ACTIVITY: Add Employee
      await ActivityService().logActivity(
        actionType: 'CREATE',
        targetCollection: 'employees',
        targetId: employee.id,
        targetName: employee.nama,
        details: 'Added new employee: ${employee.nama}',
      );
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
      
      // LOG ACTIVITY: Batch Add
      await ActivityService().logActivity(
        actionType: 'CREATE_BATCH',
        targetCollection: 'employees',
        details: 'Imported ${employees.length} employees from Excel',
      );
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
          
      // LOG ACTIVITY: Update Employee
      await ActivityService().logActivity(
        actionType: 'UPDATE',
        targetCollection: 'employees',
        targetId: employee.id,
        targetName: employee.nama,
        details: 'Updated employee details for: ${employee.nama}',
      );
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
          
      // LOG ACTIVITY: Delete Employee
      await ActivityService().logActivity(
        actionType: 'DELETE',
        targetCollection: 'employees',
        targetId: id,
        details: 'Deleted employee with ID: $id',
      );
    } catch (e) {
      debugPrint("Error deleting employee: $e");
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'Karyawan'));
    }
  }
}
