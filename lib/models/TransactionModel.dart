import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums/transaction_source_enum.dart';


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

  final TransactionSource source;
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

  // ================= FIRESTORE =================
  factory InventoryTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
            (e) => e.name.toUpperCase() == data['type'],
        orElse: () => TransactionType.addStock,
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
      source: TransactionSourceX.fromString(data['source']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // ================= OFFLINE =================
  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'],
      type: TransactionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => TransactionType.addStock,
      ),
      itemId: map['itemId'],
      itemName: map['itemName'],
      quantity: map['quantity'],
      expiry:
      map['expiry'] != null ? DateTime.parse(map['expiry']) : null,
      userId: map['userId'],
      userName: map['userName'],
      userRole: map['userRole'],
      source: TransactionSourceX.fromString(map['source']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // ================= SERIALIZE =================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'expiry': expiry?.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'source': source.value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
