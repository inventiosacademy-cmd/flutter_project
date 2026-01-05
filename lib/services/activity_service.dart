import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String userEmail;
  final String actionType; // LOGIN, LOGOUT, CREATE, UPDATE, DELETE, VIEW
  final String targetCollection; // employees, evaluasi, etc. (Optional)
  final String targetId; // ID of the item being acted upon (Optional)
  final String targetName; // Readable name (e.g. Employee Name)
  final String details;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.actionType,
    required this.targetCollection,
    required this.targetId,
    required this.targetName,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'actionType': actionType,
      'targetCollection': targetCollection,
      'targetId': targetId,
      'targetName': targetName,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(), // Use server time
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      actionType: map['actionType'] ?? 'UNKNOWN',
      targetCollection: map['targetCollection'] ?? '',
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      details: map['details'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton instance
  static final ActivityService _instance = ActivityService._internal();

  factory ActivityService() {
    return _instance;
  }

  ActivityService._internal();

  /// Logs a generic activity
  Future<void> logActivity({
    required String actionType,
    String targetCollection = '',
    String targetId = '',
    String targetName = '',
    String details = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // Cannot log if not logged in (unless it's a login attempt, handled separately if needed)

    try {
      await _firestore.collection('activity_logs').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Unknown',
        'actionType': actionType,
        'targetCollection': targetCollection,
        'targetId': targetId,
        'targetName': targetName,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("📝 Activity Logged: $actionType - $details");
    } catch (e) {
      debugPrint("❌ Failed to log activity: $e");
      // Don't rethrow, logging failure shouldn't crash the app flow
    }
  }

  /// Helper for logging Login
  Future<void> logLogin() async {
    await logActivity(
      actionType: 'LOGIN',
      details: 'User logged in successfully',
    );
  }

  /// Helper for logging Logout
  Future<void> logLogout() async {
    await logActivity(
      actionType: 'LOGOUT',
      details: 'User logged out',
    );
  }
}
