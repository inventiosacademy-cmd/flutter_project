import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/activity_service.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Safety check just in case
    if (user == null) {
        return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Aktivitas"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF8F9FA), // Soft grey background
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activity_logs')
            .where('userId', isEqualTo: user.uid) // Filter: Hanya log milik saya
            .orderBy('timestamp', descending: true)
            .limit(50) // Limit to last 50 logs for performance
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Belum ada aktivitas tercatat."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              final log = ActivityLog.fromMap(data, logs[index].id);

              return _buildLogCard(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(ActivityLog log) {
    IconData icon;
    Color color;

    switch (log.actionType) {
      case 'LOGIN':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'LOGOUT':
        icon = Icons.logout;
        color = Colors.grey;
        break;
      case 'CREATE':
      case 'CREATE_BATCH':
        icon = Icons.add_circle_outline;
        color = Colors.blue;
        break;
      case 'UPDATE':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'DELETE':
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blueGrey;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          log.details, // "Added new employee: Budi"
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              log.userEmail.isNotEmpty ? log.userEmail : "System",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
