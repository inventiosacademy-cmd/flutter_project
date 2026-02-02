import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/pkwt_document.dart';
import '../utils/error_helper.dart';

class PkwtProvider with ChangeNotifier {
  final Map<String, List<PkwtDocument>> _pkwtDocuments = {};
  final Map<String, StreamSubscription?> _subscriptions = {};
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isLoading => _isLoading;

  /// Get PKWT documents for specific employee
  List<PkwtDocument> getPkwtByEmployee(String employeeId) {
    return _pkwtDocuments[employeeId] ?? [];
  }

  /// Initialize realtime listener for employee's PKWT documents
  void initPkwtListener(String employeeId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Cancel existing subscription if any
    _subscriptions[employeeId]?.cancel();

    _isLoading = true;
    notifyListeners();

    // Subscribe to pkwt_documents subcollection
    _subscriptions[employeeId] = _firestore
        .collection('users')
        .doc(userId)
        .collection('employees')
        .doc(employeeId)
        .collection('pkwt_documents')
        .orderBy('uploadedAt', descending: true) // Latest first
        .snapshots()
        .listen((snapshot) {
      _pkwtDocuments[employeeId] = snapshot.docs.map((doc) {
        return PkwtDocument.fromMap(doc.data());
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching PKWT documents: $e');
      _isLoading = false;
      notifyListeners();
    });
  }



  /// Add new PKWT document to Firestore
  Future<void> addPkwtDocument(PkwtDocument document) async {
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
          .collection('pkwt_documents')
          .doc(document.id)
          .set(document.toMap());
      
      debugPrint('PKWT document added successfully: ${document.fileName}');
    } catch (e) {
      debugPrint('Error adding PKWT document: $e');
      throw Exception(ErrorHelper.getErrorMessage(e, context: 'menyimpan PKWT'));
    }
  }

  /// Cancel specific employee subscription
  void cancelListener(String employeeId) {
    _subscriptions[employeeId]?.cancel();
    _subscriptions.remove(employeeId);
    _pkwtDocuments.remove(employeeId);
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (var subscription in _subscriptions.values) {
      subscription?.cancel();
    }
    _subscriptions.clear();
    _pkwtDocuments.clear();
    super.dispose();
  }
}
