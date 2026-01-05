import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StockBatch {
  final int quantity;
  final DateTime expiry;

  StockBatch({
    required this.quantity,
    required this.expiry,
  });

  // ================= COPY WITH =================
  StockBatch copyWith({
    int? quantity,
    DateTime? expiry,
  }) {
    return StockBatch(
      quantity: quantity ?? this.quantity,
      expiry: expiry ?? this.expiry,
    );
  }

  // ================= HELPERS =================
  String get expiryFormatted {
    return DateFormat('MMM dd, yyyy').format(expiry);
  }

  // ================= FIRESTORE / MAP =================
  factory StockBatch.fromMap(Map<String, dynamic> map) {
    final rawExpiry = map['expiry'];

    return StockBatch(
      quantity: (map['quantity'] as num).toInt(),
      expiry: rawExpiry is Timestamp
          ? rawExpiry.toDate()
          : DateTime.parse(rawExpiry as String),
    );
  }

  // ================= SERIALIZE =================
  Map<String, dynamic> toMap() => {
    'quantity': quantity,
    'expiry': expiry.toIso8601String(),
  };

  Map<String, dynamic> toJson() => toMap();

  factory StockBatch.fromJson(Map<String, dynamic> json) =>
      StockBatch.fromMap(json);
}
