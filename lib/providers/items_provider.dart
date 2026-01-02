import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/ItemModel.dart';



class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int _limit = 20;
  final List<ItemModel> _items = [];

  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  List<ItemModel> get items => _items;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  // ================= FETCH =================
  Future<void> fetchItems({bool refresh = false}) async {
    if (_loading) return;

    if (refresh) {
      _items.clear();
      _lastDoc = null;
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore) return;

    _loading = true;
    notifyListeners();

    Query query = _firestore
        .collection('items')
        .orderBy('name')
        .limit(_limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      _items.addAll(
        snapshot.docs.map((e) => ItemModel.fromFirestore(e)).toList(),
      );
    }

    if (snapshot.docs.length < _limit) {
      _hasMore = false;
    }

    _loading = false;
    notifyListeners();
  }

  // ================= HELPERS =================
  int get totalItemCount => _items.length;

  int get totalStock =>
      _items.fold(0, (sum, item) => sum + item.totalStock);

  List<ItemModel> get lowStockItems =>
      _items.where((i) => i.isLowStock).toList();

  List<ItemModel> get nearlyExpiredItems {
    final now = DateTime.now();
    return _items.where((item) {
      return item.batches.any(
            (b) => b.expiry.difference(now).inDays <= 30,
      );
    }).toList();
  }

  Future<void> updateLowStockThreshold({
    required String itemId,
    required int value,
  }) async {
    await _firestore.collection('items').doc(itemId).update({
      'lowStockThreshold': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        lowStockThreshold: value,
      );
      notifyListeners();
    }
  }




}
