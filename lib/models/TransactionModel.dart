import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums/transaction_source_enum.dart';

enum TransactionType {
  addStock,
  dispense,
  createItem,
  // deleteItem,
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
  final String? approvedBy;

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
    this.approvedBy,
    required this.source,
    required this.timestamp,
  });

  // ================= FIRESTORE =================
  factory InventoryTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
            (e) => e.name == (data['type'] as String).toLowerCase(),
        orElse: () => TransactionType.addStock,
      ),
      itemId: data['itemId'],
      itemName: data['itemName'],
      quantity: data['quantity'],
      expiry: _parseExpiry(data['expiry']),
      userId: data['userId'],
      userName: data['userName'],
      userRole: data['userRole'],
      source: TransactionSourceX.fromString(data['source']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      approvedBy: data['approvedBy']
    );
  }

  // ================= OFFLINE / JSON =================
  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TransactionType.addStock,
      ),
      itemId: json['itemId'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      expiry: json['expiry'] != null
          ? DateTime.parse(json['expiry'])
          : null,
      userId: json['userId'],
      userName: json['userName'],
      userRole: json['userRole'],
      source: TransactionSourceX.fromString(json['source']),
      timestamp: DateTime.parse(json['timestamp']),
      approvedBy: json['approvedBy']
    );
  }

  // ================= SERIALIZE =================
  Map<String, dynamic> toJson() => {
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
    'approvedBy': approvedBy,
  };

  // ================= HELPERS =================
  static DateTime? _parseExpiry(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    throw Exception('Invalid expiry format: $value');
  }

  // ================= BACKWARD COMPAT =================
  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
