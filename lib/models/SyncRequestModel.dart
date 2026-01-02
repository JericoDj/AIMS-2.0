import 'package:cloud_firestore/cloud_firestore.dart';

class SyncRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String status;
  final DateTime createdAt;
  final List inventory;
  final List transactions;

  SyncRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.createdAt,
    required this.inventory,
    required this.transactions,
  });

  factory SyncRequest.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return SyncRequest(
      id: id,
      userId: data['userId'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      inventory: List.from(data['inventory'] ?? []),
      transactions: List.from(data['transactions'] ?? []),
    );
  }
}
