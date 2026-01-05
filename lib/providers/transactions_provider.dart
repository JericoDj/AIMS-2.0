import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/inventoryTransactionController.dart';
import '../models/TransactionModel.dart';
import 'accounts_provider.dart';

class TransactionsProvider extends ChangeNotifier {
  AccountsProvider? _accountsProvider;

  TransactionsProvider(this._accountsProvider);


  void updateAccountsProvider(AccountsProvider provider) {
    _accountsProvider = provider;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final InventoryTransactionController _controller =
  InventoryTransactionController();

  final List<InventoryTransaction> _transactions = [];
  bool _loading = false;
  bool _hasMore = true;

  static const int _limit = 20;
  DocumentSnapshot? _lastDoc;

  /// ---------------- GETTERS ----------------
  List<InventoryTransaction> get transactions =>
      List.unmodifiable(_transactions);

  bool get loading => _loading;
  bool get hasMore => _hasMore;

  // ================= DELETE =================
  Future<void> deleteTransaction(String id) async {
    await _controller.delete(id);

    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  /// ---------------- FETCH ----------------
  Future<void> fetchTransactions({bool refresh = false}) async {
    if (_loading) return;

    if (refresh) {
      _transactions.clear();
      _lastDoc = null;
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore) return;

    _loading = true;
    notifyListeners();

    Query query = _firestore
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(_limit);

    // 🔐 USER FILTER (ONLY IF USER ROLE)
    if (_accountsProvider?.isUser == true) {
      final fullName = _accountsProvider!.currentUser?.fullName;

      if (fullName != null) {
        query = query.where(
          'userName',
          whereIn: [
            fullName,
            '$fullName (Offline Sync)',
          ],
        );
      }
    }

    // PAGINATION
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;

      _transactions.addAll(
        snapshot.docs.map(
              (doc) => InventoryTransaction.fromFirestore(doc),
        ),
      );
    }

    if (snapshot.docs.length < _limit) {
      _hasMore = false;
    }

    _loading = false;
    notifyListeners();
  }

  /// ---------------- REALTIME (OPTIONAL) ----------------
  Stream<List<InventoryTransaction>> watchLatest({int limit = 10}) {
    Query query = _firestore
        .collection('transactions');

    // 🔐 USER FILTER (ONLY IF USER ROLE)
    if (_accountsProvider?.isUser == true) {
      final fullName = _accountsProvider!.currentUser?.fullName;

      if (fullName != null) {
        query = query.where(
          'userName',
          whereIn: [
            fullName,
            '$fullName (Offline Sync)',
          ],
        );
      }
    }

    // 🔽 ORDER + LIMIT (must come AFTER where)
    query = query
        .orderBy('timestamp', descending: true)
        .limit(limit);

    return query.snapshots().map(
          (snap) => snap.docs
          .map((e) => InventoryTransaction.fromFirestore(e))
          .toList(),
    );
  }


  /// ---------------- HELPERS ----------------
  InventoryTransaction? get latest =>
      _transactions.isNotEmpty ? _transactions.first : null;

  List<InventoryTransaction> byType(TransactionType type) =>
      _transactions.where((t) => t.type == type).toList();

  List<InventoryTransaction> byUser(String userId) =>
      _transactions.where((t) => t.userId == userId).toList();
}
