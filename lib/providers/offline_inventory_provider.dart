import 'package:flutter/foundation.dart';

import '../controllers/offlineInventoryController.dart';
import '../models/ItemModel.dart';
import '../utils/offline_inventory_storage.dart';

class OfflineInventoryProvider extends ChangeNotifier {
  bool loading = false;

  final List<ItemModel> _items = [];
  List<ItemModel> get items => List.unmodifiable(_items);

  final OfflineInventoryController _controller =
  OfflineInventoryController();

  bool _initialized = false;

  // ================= LOAD =================
  Future<void> loadItems() async {
    if (_initialized) {
      // Refresh from controller memory only
      _items
        ..clear()
        ..addAll(_controller.getAll());
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    // 🔑 Load disk → controller memory
    await _controller.init();

    _items
      ..clear()
      ..addAll(_controller.getAll());

    _initialized = true;
    loading = false;
    notifyListeners();
  }

  // ================= RELOAD (MEMORY ONLY) =================
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

  // ================= CLEAR EVERYTHING =================
  Future<void> clear() async {
    // 1️⃣ Clear provider state
    _items.clear();

    // 2️⃣ Clear controller memory
    _controller.clear();

    // 3️⃣ Clear disk storage
    await OfflineInventoryStorage.clear();

    // 4️⃣ Reset init flag so reload doesn't resurrect data
    _initialized = false;

    notifyListeners();
  }
}
