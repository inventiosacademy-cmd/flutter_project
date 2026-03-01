import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evaluasi.dart';
import '../utils/error_helper.dart';

class EvaluasiProvider with ChangeNotifier {
  List<Evaluasi> _evaluasiList = [];
  bool _isLoading = false;
  String? _error;

  List<Evaluasi> get evaluasiList => [..._evaluasiList];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Firestore collection reference
  CollectionReference<Map<String, dynamic>> get _evaluasiCollection {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User belum login');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('evaluasi');
  }

  // Initialize and listen to Firestore changes
  void init() {
    if (_userId == null) return;
    
    _evaluasiCollection
        .orderBy('tanggalEvaluasi', descending: true)
        .snapshots()
        .listen((snapshot) {
      _evaluasiList = snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
      notifyListeners();
    }, onError: (e) {
      _error = ErrorHelper.getErrorMessage(e, context: 'Evaluasi');
      notifyListeners();
    });
  }

  // Convert Firestore document to Evaluasi
  Evaluasi _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Evaluasi(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeePosition: data['employeePosition'] ?? '',
      employeeDepartemen: data['employeeDepartemen'] ?? '',
      atasanLangsung: data['atasanLangsung'] ?? '',
      tanggalMasuk: (data['tanggalMasuk'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalPkwtBerakhir: (data['tanggalPkwtBerakhir'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pkwtKe: data['pkwtKe'] ?? 1,
      tanggalEvaluasi: (data['tanggalEvaluasi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periode: data['periode'] ?? '',
      nilaiKinerja: data['nilaiKinerja'] ?? '',
      catatan: data['catatan'] ?? '',
      status: EvaluasiStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EvaluasiStatus.draft,
      ),
      evaluator: data['evaluator'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ratings: Evaluasi.ratingsFromJson(data['ratings'] as Map<String, dynamic>?),
      comments: Evaluasi.commentsFromJson(data['comments'] as Map<String, dynamic>?),
      recommendation: data['recommendation'] ?? 'perpanjang',
      perpanjangBulan: data['perpanjangBulan'] ?? 6,
      sakit: data['sakit'] ?? 0,
      izin: data['izin'] ?? 0,
      terlambat: data['terlambat'] ?? 0,
      mangkir: data['mangkir'] ?? 0,
      signatureBase64: data['signatureBase64'],
      atasanSignatureBase64: data['atasanSignatureBase64'],
      atasanSignatureNama: data['atasanSignatureNama'],
      atasanSignatureStatus: data['atasanSignatureStatus'],
      karyawanSignatureBase64: data['karyawanSignatureBase64'],
      karyawanSignatureNama: data['karyawanSignatureNama'],
      karyawanSignatureStatus: data['karyawanSignatureStatus'],
      hcgsAdminName: data['hcgsAdminName'] ?? '',
      hcgsSignatureBase64: data['hcgsSignatureBase64'],
      hcgsSignatureNama: data['hcgsSignatureNama'],
      hcgsSignatureStatus: data['hcgsSignatureStatus'],
      fungsionalSignatureBase64: data['fungsionalSignatureBase64'],
      fungsionalSignatureNama: data['fungsionalSignatureNama'],
      fungsionalSignatureStatus: data['fungsionalSignatureStatus'],
      atasanSignatureJabatan: data['atasanSignatureJabatan'],
      karyawanSignatureJabatan: data['karyawanSignatureJabatan'],
      hcgsSignatureJabatan: data['hcgsSignatureJabatan'],
      fungsionalSignatureJabatan: data['fungsionalSignatureJabatan'],
    );
  }

  // Convert Evaluasi to Firestore document
  Map<String, dynamic> _toFirestore(Evaluasi evaluasi) {
    return {
      'employeeId': evaluasi.employeeId,
      'employeeName': evaluasi.employeeName,
      'employeePosition': evaluasi.employeePosition,
      'employeeDepartemen': evaluasi.employeeDepartemen,
      'atasanLangsung': evaluasi.atasanLangsung,
      'tanggalMasuk': Timestamp.fromDate(evaluasi.tanggalMasuk),
      'tanggalPkwtBerakhir': Timestamp.fromDate(evaluasi.tanggalPkwtBerakhir),
      'pkwtKe': evaluasi.pkwtKe,
      'tanggalEvaluasi': Timestamp.fromDate(evaluasi.tanggalEvaluasi),
      'periode': evaluasi.periode,
      'nilaiKinerja': evaluasi.nilaiKinerja,
      'catatan': evaluasi.catatan,
      'status': evaluasi.status.name,
      'evaluator': evaluasi.evaluator,
      'createdAt': Timestamp.fromDate(evaluasi.createdAt),
      'updatedAt': Timestamp.fromDate(evaluasi.updatedAt),
      'ratings': evaluasi.ratingsJson,
      'comments': evaluasi.commentsJson,
      'recommendation': evaluasi.recommendation,
      'perpanjangBulan': evaluasi.perpanjangBulan,
      'sakit': evaluasi.sakit,
      'izin': evaluasi.izin,
      'terlambat': evaluasi.terlambat,
      'mangkir': evaluasi.mangkir,
      'signatureBase64': evaluasi.signatureBase64,
      'atasanSignatureBase64': evaluasi.atasanSignatureBase64,
      'atasanSignatureNama': evaluasi.atasanSignatureNama,
      'atasanSignatureStatus': evaluasi.atasanSignatureStatus,
      'karyawanSignatureBase64': evaluasi.karyawanSignatureBase64,
      'karyawanSignatureNama': evaluasi.karyawanSignatureNama,
      'karyawanSignatureStatus': evaluasi.karyawanSignatureStatus,
      'hcgsAdminName': evaluasi.hcgsAdminName,
      'hcgsSignatureBase64': evaluasi.hcgsSignatureBase64,
      'hcgsSignatureNama': evaluasi.hcgsSignatureNama,
      'hcgsSignatureStatus': evaluasi.hcgsSignatureStatus,
      'fungsionalSignatureBase64': evaluasi.fungsionalSignatureBase64,
      'fungsionalSignatureNama': evaluasi.fungsionalSignatureNama,
      'fungsionalSignatureStatus': evaluasi.fungsionalSignatureStatus,
      'atasanSignatureJabatan': evaluasi.atasanSignatureJabatan,
      'karyawanSignatureJabatan': evaluasi.karyawanSignatureJabatan,
      'hcgsSignatureJabatan': evaluasi.hcgsSignatureJabatan,
      'fungsionalSignatureJabatan': evaluasi.fungsionalSignatureJabatan,
    };
  }

  // Add new evaluation
  Future<void> addEvaluasi(Evaluasi evaluasi) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _evaluasiCollection.doc(evaluasi.id).set(_toFirestore(evaluasi));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = ErrorHelper.getErrorMessage(e, context: 'Evaluasi');
      notifyListeners();
      throw Exception(_error);
    }
  }

  // Update evaluation
  Future<void> updateEvaluasi(String id, Evaluasi updatedEvaluasi) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _evaluasiCollection.doc(id).update(_toFirestore(updatedEvaluasi));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = ErrorHelper.getErrorMessage(e, context: 'Evaluasi');
      notifyListeners();
      throw Exception(_error);
    }
  }

  // Delete evaluation
  Future<void> deleteEvaluasi(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _evaluasiCollection.doc(id).delete();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = ErrorHelper.getErrorMessage(e, context: 'Evaluasi');
      notifyListeners();
      throw Exception(_error);
    }
  }



  // Get filtered evaluations
  List<Evaluasi> getFilteredEvaluasi({
    String? timeFilter, // 'all', 'thisMonth', '3months', '6months', 'thisYear'
    EvaluasiStatus? statusFilter,
    String? divisiFilter,
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

    // Filter by divisi/departemen
    if (divisiFilter != null && divisiFilter.isNotEmpty) {
      filtered = filtered.where((e) => e.employeeDepartemen == divisiFilter).toList();
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
