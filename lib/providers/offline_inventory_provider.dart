import 'package:flutter/foundation.dart';

import '../controllers/offlineInventoryController.dart';
import '../models/ItemModel.dart';

class OfflineInventoryProvider extends ChangeNotifier {
  bool loading = false;

  final List<ItemModel> _items = [];
  List<ItemModel> get items => List.unmodifiable(_items);

  final OfflineInventoryController _controller =
  OfflineInventoryController();

  bool _initialized = false;

  // ================= LOAD / RELOAD =================
  Future<void> loadItems() async {
    if (_initialized) {
      // already loaded once, just refresh memory
      _items
        ..clear()
        ..addAll(_controller.getAll());
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    // 🔑 CRITICAL: load from disk → controller memory
    await _controller.init();

    _items
      ..clear()
      ..addAll(_controller.getAll());

    _initialized = true;
    loading = false;
    notifyListeners();
  }

  /// 🔄 Explicit async reload
  Future<void> reload() async {
    loading = true;
    notifyListeners();

    _items
      ..clear()
      ..addAll(_controller.getAll());

    loading = false;
    notifyListeners();
  }

  // ================= MUTATIONS =================
  void addItem(ItemModel item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem(ItemModel item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
