import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/ItemModel.dart';
import '../models/StockBatchModel.dart';
import '../models/TransactionModel.dart';
import '../providers/offline_transaction_provider.dart';

import '../utils/enums/transaction_source_enum.dart';
import '../utils/offline_inventory_storage.dart';
import '../utils/offline_qr_util.dart';

class OfflineInventoryController {
  static final List<ItemModel> _items = [];
  final _uuid = const Uuid();

  // ================= NORMALIZE =================
  String normalizeItemName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  // ================= INIT =================
  Future<void> init() async {
    if (_items.isNotEmpty) return;

    debugPrint('📦 [OFFLINE] Loading items from disk...');
    final loaded = await OfflineInventoryStorage.load();

    _items
      ..clear()
      ..addAll(loaded);

    debugPrint('✅ [OFFLINE] Loaded ${_items.length} items');
  }

  void clear() {
    _items.clear();
  }

  // ================= CREATE ITEM =================
  Future<String> createItem({
    required String name,
    required String category,
  }) async {
    debugPrint('🧾 [OFFLINE] Creating item: $name');

    final itemId = _uuid.v4();

    // ✅ Generate offline QR (SAME payload as online)
    final qrPath = await OfflineQrUtil.generateAndSaveQr(
      itemId: itemId,
    );

    final item = ItemModel(
      id: itemId,
      name: name,
      category: category,
      barcode: itemId,               // payload
      barcodeImageUrl: qrPath,        // local file path
      nameNormalized: normalizeItemName(name),
      batches: [],
    );

    _items.add(item);
    await OfflineInventoryStorage.save(_items);

    OfflineTransactionsProvider.instance.add(
      InventoryTransaction(
        id: _uuid.v4(),
        source: TransactionSource.offline,
        type: TransactionType.createItem,
        itemId: itemId,
        itemName: name,
        timestamp: DateTime.now(),
      ),
    );

    return itemId;
  }

  // ================= EXISTS =================
  Future<bool> itemNameExists(String name) async {
    final key = normalizeItemName(name);
    return _items.any((i) => i.nameNormalized == key);
  }

  // ================= ADD STOCK =================
  Future<void> addStock({
    required String itemId,
    required int quantity,
    required DateTime expiry,
  }) async {
    final item = _items.firstWhere((i) => i.id == itemId);

    final List<StockBatch> updatedBatches = [];
    bool merged = false;

    for (final batch in item.batches) {
      if (!merged && batch.expiry.isAtSameMomentAs(expiry)) {
        // 🔁 Replace matching batch
        updatedBatches.add(
          StockBatch(
            quantity: batch.quantity + quantity,
            expiry: batch.expiry,
          ),
        );
        merged = true;
      } else {
        updatedBatches.add(batch);
      }
    }

    // ➕ No existing batch → add new
    if (!merged) {
      updatedBatches.add(
        StockBatch(
          quantity: quantity,
          expiry: expiry,
        ),
      );
    }

    // 🔄 Replace item batches atomically
    item.batches
      ..clear()
      ..addAll(updatedBatches);

    await OfflineInventoryStorage.save(_items);

    // 🧾 Log transaction
    OfflineTransactionsProvider.instance.add(
      InventoryTransaction(
        id: _uuid.v4(),
        source: TransactionSource.offline,
        type: TransactionType.addStock,
        itemId: itemId,
        itemName: item.name,
        quantity: quantity,
        expiry: expiry,
        timestamp: DateTime.now(),
      ),
    );
  }


  // ================= DISPENSE FIFO =================
  Future<void> dispenseStock({
    required String itemId,
    required int quantity,
  }) async {
    final item = _items.firstWhere((i) => i.id == itemId);

    // FIFO
    final sorted = [...item.batches]..sort(
          (a, b) => a.expiry.compareTo(b.expiry),
    );

    int remaining = quantity;
    final List<StockBatch> updatedBatches = [];

    for (final batch in sorted) {
      if (remaining <= 0) {
        updatedBatches.add(batch);
        continue;
      }

      if (batch.quantity <= remaining) {
        remaining -= batch.quantity;
        // batch fully consumed → DO NOT add
      } else {
        updatedBatches.add(
          StockBatch(
            quantity: batch.quantity - remaining,
            expiry: batch.expiry,
          ),
        );
        remaining = 0;
      }
    }

    if (remaining > 0) {
      throw Exception('Insufficient stock');
    }

    item.batches
      ..clear()
      ..addAll(updatedBatches);

    await OfflineInventoryStorage.save(_items);

    OfflineTransactionsProvider.instance.add(
      InventoryTransaction(
        source: TransactionSource.offline,
        type: TransactionType.dispense,
        itemId: itemId,
        itemName: item.name,
        quantity: quantity,
        timestamp: DateTime.now(), id: '',
      ),
    );
  }


  // ================= DELETE =================
  Future<void> deleteItem({
    required String itemId,
    required String itemName,
  }) async {
    _items.removeWhere((i) => i.id == itemId);

    await OfflineInventoryStorage.save(_items);

    OfflineTransactionsProvider.instance.add(
      InventoryTransaction(
        id: _uuid.v4(),
        source: TransactionSource.offline,
        type: TransactionType.deleteItem,
        itemId: itemId,
        itemName: itemName,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ================= GET =================
  List<ItemModel> getAll() => List.unmodifiable(_items);
}
