import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/evaluasi.dart';

class EvaluasiProvider with ChangeNotifier {
  final List<Evaluasi> _evaluasiList = [];

  List<Evaluasi> get evaluasiList => [..._evaluasiList];

  // Add new evaluation
  void addEvaluasi(Evaluasi evaluasi) {
    _evaluasiList.add(evaluasi);
    notifyListeners();
  }

  // Update evaluation
  void updateEvaluasi(String id, Evaluasi updatedEvaluasi) {
    final index = _evaluasiList.indexWhere((e) => e.id == id);
    if (index != -1) {
      _evaluasiList[index] = updatedEvaluasi;
      notifyListeners();
    }
  }

  // Delete evaluation
  void deleteEvaluasi(String id) {
    _evaluasiList.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Get filtered evaluations
  List<Evaluasi> getFilteredEvaluasi({
    String? timeFilter, // 'all', 'thisMonth', '3months', '6months', 'thisYear'
    EvaluasiStatus? statusFilter,
    String? searchQuery,
  }) {
    var filtered = [..._evaluasiList];

    // Filter by time
    if (timeFilter != null && timeFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((e) {
        switch (timeFilter) {
          case 'thisMonth':
            return e.tanggalEvaluasi.year == now.year &&
                e.tanggalEvaluasi.month == now.month;
          case '3months':
            final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
            return e.tanggalEvaluasi.isAfter(threeMonthsAgo);
          case '6months':
            final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
            return e.tanggalEvaluasi.isAfter(sixMonthsAgo);
          case 'thisYear':
            return e.tanggalEvaluasi.year == now.year;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by status
    if (statusFilter != null) {
      filtered = filtered.where((e) => e.status == statusFilter).toList();
    }

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.employeeName.toLowerCase().contains(query) ||
            e.employeePosition.toLowerCase().contains(query) ||
            e.periode.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.tanggalEvaluasi.compareTo(a.tanggalEvaluasi));

    return filtered;
  }

  // Get evaluations by employee
  List<Evaluasi> getEvaluasiByEmployee(String employeeId) {
    return _evaluasiList
        .where((e) => e.employeeId == employeeId)
        .toList()
      ..sort((a, b) => b.tanggalEvaluasi.compareTo(a.tanggalEvaluasi));
  }

  // Get stats
  Map<String, int> getStats() {
    return {
      'total': _evaluasiList.length,
      'draft': _evaluasiList.where((e) => e.status == EvaluasiStatus.draft).length,
      'belumTTD': _evaluasiList.where((e) => e.status == EvaluasiStatus.belumTTD).length,
      'selesai': _evaluasiList.where((e) => e.status == EvaluasiStatus.selesai).length,
    };
  }
}
