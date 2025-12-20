import 'package:cloud_firestore/cloud_firestore.dart';

import 'StockBatchModel.dart';

class ItemModel {
  final String id;
  final String name;
  final String category;
  final List<StockBatch> batches;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.batches,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ItemModel(
      id: doc.id,
      name: data['name'],
      category: data['category'],
      batches: (data['batches'] as List)
          .map((e) => StockBatch.fromMap(e))
          .toList(),
    );
  }

  int get totalStock =>
      batches.fold(0, (sum, b) => sum + b.quantity);

  /// Sorted by expiry (FIFO)
  List<StockBatch> get fifoBatches {
    final sorted = [...batches];
    sorted.sort((a, b) => a.expiry.compareTo(b.expiry));
    return sorted;
  }
}
