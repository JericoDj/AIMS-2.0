import 'package:flutter/cupertino.dart';
import '../models/TransactionModel.dart';

class OfflineTransactionsProvider extends ChangeNotifier {
  // ================= SINGLETON =================
  static final OfflineTransactionsProvider instance =
  OfflineTransactionsProvider._internal();

  factory OfflineTransactionsProvider() => instance;

  OfflineTransactionsProvider._internal();

  // ================= STATE =================
  bool _loading = false;
  final List<InventoryTransaction> _transactions = [];

  // ================= GETTERS =================
  bool get loading => _loading;

  List<InventoryTransaction> get transactions =>
      List.unmodifiable(_transactions);

  List<InventoryTransaction> latest({int limit = 5}) {
    return _transactions.take(limit).toList();
  }

  // ================= ACTIONS =================
  void loadTransactions() {
    _loading = true;
    notifyListeners();

    // TODO: Load from SQLite
    // Example:
    // _transactions = await transactionDao.getAll();

    _loading = false;
    notifyListeners();
  }

  void add(InventoryTransaction tx) {
    _transactions.insert(0, tx); // newest first
    notifyListeners();
  }

  void clear() {
    _transactions.clear();
    notifyListeners();
  }
}
