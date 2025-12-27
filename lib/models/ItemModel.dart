import 'package:cloud_firestore/cloud_firestore.dart';

import 'StockBatchModel.dart';

class ItemModel {
  final String id;
  final String name;
  final String category;

  /// 🔐 Encrypted barcode value
  final String? barcode;

  /// 🖼 Barcode image URL (Firebase Storage)
  final String? barcodeImageUrl;

  /// 🔍 Normalized name (vitamin c → vitaminc)
  final String? nameNormalized;

  final List<StockBatch> batches;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    this.barcode,
    this.barcodeImageUrl,
    this.nameNormalized,
    required this.batches,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      barcode: data['barcode'],
      barcodeImageUrl: data['barcode_image_url'],
      nameNormalized: data['name_key'],
      batches: (data['batches'] as List? ?? [])
          .map((e) => StockBatch.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  // ================= TOTAL STOCK =================
  int get totalStock =>
      batches.fold(0, (sum, b) => sum + b.quantity);

  // ================= FIFO =================
  List<StockBatch> get fifoBatches {
    final sorted = [...batches];
    sorted.sort((a, b) => a.expiry.compareTo(b.expiry));
    return sorted;
  }

  // ================= NEAREST EXPIRY =================
  DateTime? get nearestExpiry {
    if (batches.isEmpty) return null;
    return fifoBatches.first.expiry;
  }

  String get nearestExpiryFormatted {
    final exp = nearestExpiry;
    if (exp == null) return '-';
    return exp.toIso8601String().split('T').first;
  }
}
