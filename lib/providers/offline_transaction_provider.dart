import 'package:flutter/foundation.dart';

import '../models/TransactionModel.dart';
import '../utils/offline_transactions_storage.dart';
class OfflineTransactionsProvider extends ChangeNotifier {
  static final OfflineTransactionsProvider instance =
  OfflineTransactionsProvider._internal();

  factory OfflineTransactionsProvider() => instance;
  OfflineTransactionsProvider._internal();

  bool _loading = false;
  bool _initialized = false;

  final List<InventoryTransaction> _transactions = [];

  bool get loading => _loading;
  bool get initialized => _initialized;

  List<InventoryTransaction> get transactions =>
      List.unmodifiable(_transactions);

  List<InventoryTransaction> latest({int limit = 5}) =>
      _transactions.take(limit).toList();

  Future<void> loadTransactions() async {
    if (_initialized || _loading) return;

    _loading = true;
    notifyListeners();

    final loaded = await OfflineTransactionsStorage.load();

    _transactions
      ..clear()
      ..addAll(loaded.reversed);

    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> add(InventoryTransaction tx) async {
    if (!_initialized) {
      final loaded = await OfflineTransactionsStorage.load();
      _transactions
        ..clear()
        ..addAll(loaded.reversed);
      _initialized = true;
    }

    _transactions.insert(0, tx);
    await OfflineTransactionsStorage.save(_transactions);
    notifyListeners();
  }

  Future<void> clear() async {
    _transactions.clear();
    _initialized = false;
    await OfflineTransactionsStorage.clear();
    notifyListeners();
  }
}

