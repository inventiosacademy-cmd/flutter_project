import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/evaluation_upload.dart';
import '../utils/error_helper.dart';

class EvaluationUploadProvider with ChangeNotifier {
  final Map<String, List<EvaluationUpload>> _evaluationUploads = {};
  final Map<String, StreamSubscription?> _subscriptions = {};
  StreamSubscription? _globalSubscription;
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

  /// Start a global realtime listener across ALL employees using a collectionGroup query.
  /// This allows the dashboard to reactively know upload status for every employee.
  void initGlobalListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _globalSubscription?.cancel();

    // Listen to the employees collection for this user.
    // For each employee found, initialise a per-employee evaluation_uploads
    // listener (which uses the specific path already allowed by Firestore rules).
    _globalSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('employees')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final empId = doc.id;
        // Only create a listener if one doesn't already exist
        if (!_subscriptions.containsKey(empId)) {
          initEvaluationListener(empId);
        }
      }
    }, onError: (e) {
      debugPrint('EvaluationUploadProvider: global listener error: $e');
    });
  }

  /// Stop global listener
  void cancelGlobalListener() {
    _globalSubscription?.cancel();
    _globalSubscription = null;
  }


  /// Initialize realtime listener for employee's evaluation uploads
  void initEvaluationListener(String employeeId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Cancel existing subscription if any
    _subscriptions[employeeId]?.cancel();

    _isLoading = true;
    notifyListeners();

    // Subscribe to evaluation_uploads subcollection
    _subscriptions[employeeId] = _firestore
        .collection('users')
        .doc(userId)
        .collection('employees')
        .doc(employeeId)
        .collection('evaluation_uploads')
        .orderBy('uploadedAt', descending: true) // Latest first
        .snapshots()
        .listen((snapshot) {
      _evaluationUploads[employeeId] = snapshot.docs.map((doc) {
        return EvaluationUpload.fromMap(doc.data());
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching evaluation uploads: $e');
      _isLoading = false;
      notifyListeners();
    });
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

      // Clear pending flag for this employee + pkwtKe
      _pendingManualEvals[document.employeeId]?.remove(document.pkwtKe);
      
      debugPrint('Evaluation upload added successfully: ${document.fileName}');
    } catch (e) {
      debugPrint('Error adding evaluation upload: $e');
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'menyimpan evaluasi'));
    }
  }

  /// Cancel specific employee subscription
  void cancelListener(String employeeId) {
    _subscriptions[employeeId]?.cancel();
    _subscriptions.remove(employeeId);
    _evaluationUploads.remove(employeeId);
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _globalSubscription?.cancel();
    for (var subscription in _subscriptions.values) {
      subscription?.cancel();
    }
    _subscriptions.clear();
    _evaluationUploads.clear();
    super.dispose();
  }
}
