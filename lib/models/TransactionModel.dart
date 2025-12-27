import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  addStock,
  dispense,
  createItem,
  deleteItem,
}

class InventoryTransaction {
  final String id;
  final TransactionType type;
  final String itemId;
  final String itemName;
  final int? quantity;
  final DateTime? expiry;
  final String? userId;
  final String? userName;
  final String? userRole;
  final String source;
  final DateTime timestamp;

  InventoryTransaction({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    this.quantity,
    this.expiry,
    this.userId,
    this.userName,
    this.userRole,
    required this.source,
    required this.timestamp,
  });

  factory InventoryTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
            (e) => e.name.toUpperCase() == data['type'],
      ),
      itemId: data['itemId'],
      itemName: data['itemName'],
      quantity: data['quantity'],
      expiry: data['expiry'] != null
          ? DateTime.parse(data['expiry'])
          : null,
      userId: data['userId'],
      userName: data['userName'],
      userRole: data['userRole'],
      source: data['source'] ?? 'ONLINE',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
