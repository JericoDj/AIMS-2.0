import '../models/ItemUsage.dart';
import '../providers/items_provider.dart';
import '../providers/transactions_provider.dart';
import '../models/TransactionModel.dart';

class DashboardAnalyticsController {
  // ================= INVENTORY COUNTS =================
  static int lowStockCount(InventoryProvider p) =>
      p.lowStockItems.length;

  static int outOfStockCount(InventoryProvider p) =>
      p.items.where((i) => i.isOutOfStock).length;

  static int nearlyExpiryCount(InventoryProvider p) =>
      p.nearlyExpiredItems.length;

  // ================= CURRENT MONTH DISPENSE =================
  static int totalDispensedThisMonth(TransactionsProvider p) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return p.transactions
        .where((tx) =>
    tx.type == TransactionType.dispense &&
        tx.timestamp.isAfter(startOfMonth))
        .fold(0, (sum, tx) => sum + (tx.quantity ?? 0));
  }

  // ================= TOP DISPENSED ITEMS =================
  static List<ItemUsage> topDispensedItems(
      TransactionsProvider p, {
        int limit = 5,
      }) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // itemId -> ItemUsage
    final Map<String, ItemUsage> map = {};

    for (final tx in p.transactions) {
      if (tx.type != TransactionType.dispense) continue;
      if (tx.timestamp.isBefore(startOfMonth)) continue;

      final id = tx.itemId;            // ✅ REQUIRED
      final name = tx.itemName;
      final qty = tx.quantity ?? 0;

      if (map.containsKey(id)) {
        map[id] = ItemUsage(
          itemId: id,
          itemName: name,
          totalDispensed:
          map[id]!.totalDispensed + qty,
        );
      } else {
        map[id] = ItemUsage(
          itemId: id,                  // ✅ FIX
          itemName: name,
          totalDispensed: qty,
        );
      }
    }

    final list = map.values.toList()
      ..sort(
            (a, b) => b.totalDispensed.compareTo(a.totalDispensed),
      );

    return list.take(limit).toList();
  }
}
