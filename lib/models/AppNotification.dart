import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String itemId;
  final String itemName;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final type = data['type'] ?? '';

    return AppNotification(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      type: type,
      title: _titleFromType(type),
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      itemId: itemId,
      itemName: itemName,
      title: title,
      message: message,
      type: type,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  // ---------------- HELPERS ----------------
  static String _titleFromType(String type) {
    switch (type) {
      case 'LOW_STOCK':
        return 'Low Stock';
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      case 'NEAR_EXPIRY':
        return 'Near Expiry';
      case 'DISPENSE':
        return 'Item Dispensed';
      case 'STOCK_ADDED':
        return 'Stock Added';
      default:
        return 'Notification';
    }
  }
}
