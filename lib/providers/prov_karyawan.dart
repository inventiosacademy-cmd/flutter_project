import 'package:flutter/material.dart';
import '../models/karyawan.dart';
import '../models/evaluasi.dart';

class EmployeeProvider with ChangeNotifier {
  final List<Employee> _employees = [];
  final Map<String, List<Evaluation>> _evaluations = {};

  List<Employee> get employees => [..._employees]; // Return copy

  List<Evaluation> get evaluations {
    return _evaluations.values.expand((list) => list).toList();
  }

  List<Employee> get expiringContracts {
    return _employees.where((e) {
      final days = e.hariMenujuExpired;
      return days >= 0 && days < 30; // Notifikasi jika kurang dari 30 hari tapi belum expired
    }).toList();
  }

  void addEmployee(Employee employee) {
    _employees.add(employee);
    notifyListeners();
  }

  void deleteEmployee(String id) {
    _employees.removeWhere((element) => element.id == id);
    _evaluations.remove(id); // Remove associated evaluations
    notifyListeners();
  }

  void addEvaluation(Evaluation evaluation) {
    if (!_evaluations.containsKey(evaluation.employeeId)) {
      _evaluations[evaluation.employeeId] = [];
    }
    _evaluations[evaluation.employeeId]!.add(evaluation);
    notifyListeners();
  }

  List<Evaluation> getEvaluations(String employeeId) {
    return _evaluations[employeeId] ?? [];
  }
}
