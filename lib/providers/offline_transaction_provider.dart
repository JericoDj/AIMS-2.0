import 'package:flutter/foundation.dart';

import '../models/TransactionModel.dart';
import '../utils/offline_transactions_storage.dart';

class OfflineTransactionsProvider extends ChangeNotifier {
  // ================= SINGLETON =================
  static final OfflineTransactionsProvider instance =
  OfflineTransactionsProvider._internal();

  factory OfflineTransactionsProvider() => instance;
  OfflineTransactionsProvider._internal();

  // ================= STATE =================
  bool _loading = false;
  bool _initialized = false;

  final List<InventoryTransaction> _transactions = [];

  // ================= GETTERS =================
  bool get loading => _loading;

  List<InventoryTransaction> get transactions =>
      List.unmodifiable(_transactions);

  List<InventoryTransaction> latest({int limit = 5}) =>
      _transactions.take(limit).toList();

  // ================= LOAD =================
  Future<void> loadTransactions() async {
    if (_initialized || _loading) return;

    _loading = true;
    notifyListeners();

    final loaded = await OfflineTransactionsStorage.load();

    _transactions
      ..clear()
      ..addAll(loaded.reversed); // newest first

    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  // ================= ADD =================
  Future<void> add(InventoryTransaction tx) async {
    _transactions.insert(0, tx);
    await OfflineTransactionsStorage.save(_transactions);
    notifyListeners();
  }

  // ================= CLEAR =================
  Future<void> clear() async {
    _transactions.clear();
    await OfflineTransactionsStorage.clear();
    notifyListeners();
  }
}
