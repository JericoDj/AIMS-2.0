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

  // 📈 STOCK HISTORY
  final int maxStock;

  // 🔔 LOW STOCK CONFIG
  final int lowStockThreshold;

  // 🔔 NOTIFICATION FLAG
  final bool lowStockNotified;

  // 🔴 OFFLINE ONLY (stock debt)
  int excessUsage;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    this.barcode,
    this.barcodeImageUrl,
    this.nameNormalized,
    required this.batches,
    this.maxStock = 0,
    this.lowStockThreshold = 10,
    this.lowStockNotified = false,
    this.excessUsage = 0,
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
      maxStock: data['maxStock'] ?? 0,
      lowStockThreshold: data['lowStockThreshold'] ?? 10,
      lowStockNotified: data['lowStockNotified'] ?? false,
      excessUsage: data['excessUsage'] ?? 0,
      batches: (data['batches'] as List? ?? [])
          .map((e) => StockBatch.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }


  // ================= LOCAL JSON =================
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      barcode: json['barcode'],
      barcodeImageUrl: json['barcodeImageUrl'],
      nameNormalized: json['nameNormalized'],
      maxStock: json['maxStock'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'] ?? 10,
      lowStockNotified: json['lowStockNotified'] ?? false,
      excessUsage: json['excessUsage'] ?? 0,
      batches: (json['batches'] as List? ?? [])
          .map((e) => StockBatch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'barcode': barcode,
    'barcodeImageUrl': barcodeImageUrl,
    'nameNormalized': nameNormalized,
    'maxStock': maxStock,
    'lowStockThreshold': lowStockThreshold,
    'lowStockNotified': lowStockNotified,
    'excessUsage': excessUsage,
    'batches': batches.map((b) => b.toJson()).toList(),
  };


  // ================= IMMUTABLE UPDATE =================
  ItemModel copyWith({
    String? name,
    String? category,
    String? barcode,
    String? barcodeImageUrl,
    String? nameNormalized,
    List<StockBatch>? batches,
    int? maxStock,
    int? lowStockThreshold,
    bool? lowStockNotified,
    int? excessUsage,
  }) {
    return ItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      barcodeImageUrl: barcodeImageUrl ?? this.barcodeImageUrl,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      batches: batches ?? this.batches,
      maxStock: maxStock ?? this.maxStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      lowStockNotified: lowStockNotified ?? this.lowStockNotified,
      excessUsage: excessUsage ?? this.excessUsage,
    );
  }
  // ================= HELPERS =================


  int get autoLowStockThreshold {
    if (maxStock <= 0) return lowStockThreshold;
    return (maxStock * 0.5).round();
  }


  int get totalStock =>
      batches.fold(0, (sum, b) => sum + b.quantity);

  /// ✅ OFFLINE-AWARE DISPLAY VALUE
  int get displayStock {
    if (totalStock > 0) return totalStock;
    if (excessUsage > 0) return -excessUsage;
    return 0;
  }

  bool get hasExcess => excessUsage > 0;

  List<StockBatch> get fifoBatches {
    final sorted = [...batches];
    sorted.sort((a, b) => a.expiry.compareTo(b.expiry));
    return sorted;
  }

  int get resolvedLowStockThreshold => lowStockThreshold;

  DateTime? get nearestExpiry =>
      batches.isEmpty ? null : fifoBatches.first.expiry;

  String get nearestExpiryFormatted =>
      nearestExpiry != null
          ? nearestExpiry!.toIso8601String().split('T').first
          : '-';

  // ================= STATUS =================
  bool get isOutOfStock => displayStock <= 0;

  bool get isLowStock =>
      totalStock > 0 && totalStock <= autoLowStockThreshold;
}
