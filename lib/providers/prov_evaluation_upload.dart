import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/evaluation_upload.dart';
import '../utils/error_helper.dart';

class EvaluationUploadProvider with ChangeNotifier {
  final Map<String, List<EvaluationUpload>> _evaluationUploads = {};
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// In-memory: tracks employees who had the blank template printed/downloaded
  /// but haven't uploaded the filled PDF yet.
  final Map<String, Set<int>> _pendingManualEvals = {};

  bool get isLoading => _isLoading;

  /// Get evaluation uploads for specific employee
  List<EvaluationUpload> getEvaluationsByEmployee(String employeeId) {
    return _evaluationUploads[employeeId] ?? [];
  }

  /// Get ALL uploads across all employees as a flat list
  List<EvaluationUpload> get allUploads =>
      _evaluationUploads.values.expand((list) => list).toList();

  /// Total number of manual evaluation uploads
  int get totalUploads => allUploads.length;

  /// Check whether a manual evaluation upload exists for a given employee + pkwtKe.
  /// Used by the dashboard to determine "sudah evaluasi" status.
  bool hasEvaluationUpload(String employeeId, int pkwtKe) {
    return (_evaluationUploads[employeeId] ?? [])
        .any((u) => u.pkwtKe == pkwtKe);
  }

  // ── Pending manual evals (template printed, not yet uploaded) ──────────────

  /// Mark that a blank template was printed/downloaded for this employee.
  void markPendingManualEval(String employeeId, int pkwtKe) {
    _pendingManualEvals.putIfAbsent(employeeId, () => {}).add(pkwtKe);
    notifyListeners();
  }

  bool hasPendingManualEval(String employeeId, int pkwtKe) =>
      _pendingManualEvals[employeeId]?.contains(pkwtKe) ?? false;

  /// Returns pending entries that haven't been uploaded yet.
  List<({String employeeId, int pkwtKe})> get pendingManualEvals {
    final list = <({String employeeId, int pkwtKe})>[];
    for (final entry in _pendingManualEvals.entries) {
      for (final ke in entry.value) {
        if (!hasEvaluationUpload(entry.key, ke)) {
          list.add((employeeId: entry.key, pkwtKe: ke));
        }
      }
    }
    return list;
  }

  /// Load evaluation uploads for an employee only once
  Future<void> loadEvaluationUploads(String employeeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('employees')
          .doc(employeeId)
          .collection('evaluation_uploads')
          .orderBy('uploadedAt', descending: true)
          .get();

      _evaluationUploads[employeeId] = snapshot.docs.map((doc) {
        return EvaluationUpload.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error fetching evaluation uploads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  /// Add new evaluation upload to Firestore
  Future<void> addEvaluationUpload(EvaluationUpload document) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak terautentikasi');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('employees')
          .doc(document.employeeId)
          .collection('evaluation_uploads')
          .doc(document.id)
          .set(document.toMap());

      // Tulis manual ke RAM
      if (_evaluationUploads[document.employeeId] == null) {
        _evaluationUploads[document.employeeId] = [];
      }
      _evaluationUploads[document.employeeId]!.insert(0, document);

      // Clear pending flag for this employee + pkwtKe
      _pendingManualEvals[document.employeeId]?.remove(document.pkwtKe);
      
      debugPrint('Evaluation upload added successfully: ${document.fileName}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding evaluation upload: $e');
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'menyimpan evaluasi'));
    }
  }

  /// Remove loaded uploads from RAM
  void cleanupEmployeeData(String employeeId) {
    _evaluationUploads.remove(employeeId);
    notifyListeners();
  }

  @override
  void dispose() {
    _evaluationUploads.clear();
    super.dispose();
  }
}
