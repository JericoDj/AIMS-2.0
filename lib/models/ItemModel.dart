import 'package:cloud_firestore/cloud_firestore.dart';
import 'StockBatchModel.dart';

class ItemModel {
  final String id;
  final String name;
  final String category;
  final String? barcode;
  final String? barcodeImageUrl;
  final String? nameNormalized;
  final List<StockBatch> batches;

  // ✅ NEW
  final int lowStockThreshold;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    this.barcode,
    this.barcodeImageUrl,
    this.nameNormalized,
    required this.batches,
    this.lowStockThreshold = 10, // default safe value
  });

  // ================= FIRESTORE =================
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      barcode: data['barcode'],
      barcodeImageUrl: data['barcode_image_url'],
      nameNormalized: data['name_key'],
      lowStockThreshold: data['lowStockThreshold'] ?? 10,
      batches: (data['batches'] as List? ?? [])
          .map(
            (e) => StockBatch.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
    );
  }

  // ================= LOCAL JSON =================
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'barcode': barcode,
    'barcodeImageUrl': barcodeImageUrl,
    'nameNormalized': nameNormalized,
    'lowStockThreshold': lowStockThreshold,
    'batches': batches.map((b) => b.toJson()).toList(),
  };

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      barcode: json['barcode'],
      barcodeImageUrl: json['barcodeImageUrl'],
      nameNormalized: json['nameNormalized'],
      lowStockThreshold: json['lowStockThreshold'] ?? 10,
      batches: (json['batches'] as List? ?? [])
          .map(
            (e) => StockBatch.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
    );
  }

  // ================= IMMUTABLE UPDATE =================
  ItemModel copyWith({
    String? name,
    String? category,
    String? barcode,
    String? barcodeImageUrl,
    String? nameNormalized,
    List<StockBatch>? batches,
    int? lowStockThreshold,
  }) {
    return ItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      barcodeImageUrl: barcodeImageUrl ?? this.barcodeImageUrl,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      batches: batches ?? this.batches,
      lowStockThreshold:
      lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  // ================= HELPERS =================
  int get totalStock =>
      batches.fold(0, (sum, b) => sum + b.quantity);

  List<StockBatch> get fifoBatches {
    final sorted = [...batches];
    sorted.sort((a, b) => a.expiry.compareTo(b.expiry));
    return sorted;
  }

  DateTime? get nearestExpiry =>
      batches.isEmpty ? null : fifoBatches.first.expiry;

  String get nearestExpiryFormatted =>
      nearestExpiry != null
          ? nearestExpiry!.toIso8601String().split('T').first
          : '-';

  // ================= STATUS =================
  bool get isOutOfStock => totalStock == 0;

  bool get isLowStock =>
      totalStock > 0 && totalStock <= lowStockThreshold;
}
