import 'package:flutter/cupertino.dart';

import '../controllers/offlineInventoryController.dart';
import '../models/ItemModel.dart';

class OfflineInventoryProvider extends ChangeNotifier {
  bool loading = false;

  final List<ItemModel> _items = [];

  List<ItemModel> get items => List.unmodifiable(_items);

  final OfflineInventoryController _controller =
  OfflineInventoryController();

  // ================= LOAD / RELOAD =================
  void loadItems() {
    loading = true;
    notifyListeners();

    _items
      ..clear()
      ..addAll(_controller.getAll());

    loading = false;
    notifyListeners();
  }

  /// 🔄 Alias for consistency with Online provider
  void reload() {
    loadItems();
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
