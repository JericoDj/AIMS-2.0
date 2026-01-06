import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../models/TransactionModel.dart';
import '../controllers/inventoryTransactionController.dart';

class SyncProvider extends ChangeNotifier {
  final GetStorage _box = GetStorage("current_user");

  static const String _offlineTransactionsKey = 'offline_transactions';

  bool _syncing = false;
  bool _hasPendingSync = false;

  List<InventoryTransaction> _pendingTransactions = [];

  bool get syncing => _syncing;
  bool get hasPendingSync => _hasPendingSync;
  List<InventoryTransaction> get pendingTransactions =>
      List.unmodifiable(_pendingTransactions);

  SyncProvider() {
    loadPendingSync();
  }

  // ================= LOAD =================
  void loadPendingSync() {
    final data = _box.read<List>(_offlineTransactionsKey) ?? [];

    _pendingTransactions = data
        .map((e) =>
        InventoryTransaction.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    _hasPendingSync = _pendingTransactions.isNotEmpty;
    notifyListeners();
  }

  // ================= REQUEST SYNC =================
  void requestSync(InventoryTransaction tx) {
    _pendingTransactions.add(tx);

    _box.write(
      _offlineTransactionsKey,
      _pendingTransactions.map((e) => e.toMap()).toList(),
    );

    _hasPendingSync = true;
    notifyListeners();
  }

  // ================= PERFORM SYNC =================
  Future<void> performSync() async {
    if (_syncing || _pendingTransactions.isEmpty) return;

    _syncing = true;
    notifyListeners();

    try {
      for (final tx in _pendingTransactions) {
        // 🔥 Upload to Firestore via controller
        await InventoryTransactionController().sync(tx);
      }

      // 🧹 Clear offline data
      _pendingTransactions.clear();
      _box.remove(_offlineTransactionsKey);

      _hasPendingSync = false;
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    }

    _syncing = false;
    notifyListeners();
  }

  // ================= CLEAR =================
  void clearSync() {
    _pendingTransactions.clear();
    _box.remove(_offlineTransactionsKey);
    _hasPendingSync = false;
    notifyListeners();
  }
}
