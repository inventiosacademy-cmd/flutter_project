import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/evaluation_upload.dart';

class EvaluationUploadProvider with ChangeNotifier {
  final Map<String, List<EvaluationUpload>> _evaluationUploads = {};
  final Map<String, StreamSubscription?> _subscriptions = {};
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isLoading => _isLoading;

  /// Get evaluation uploads for specific employee
  List<EvaluationUpload> getEvaluationsByEmployee(String employeeId) {
    return _evaluationUploads[employeeId] ?? [];
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
      
      debugPrint('Evaluation upload added successfully: ${document.fileName}');
    } catch (e) {
      debugPrint('Error adding evaluation upload:$e');
      rethrow;
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
    for (var subscription in _subscriptions.values) {
      subscription?.cancel();
    }
    _subscriptions.clear();
    _evaluationUploads.clear();
    super.dispose();
  }
}
