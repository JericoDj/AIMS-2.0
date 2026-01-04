import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/SyncRequestModel.dart';
import '../models/TransactionModel.dart';
import 'inventoryController.dart';
import 'inventoryTransactionController.dart';

class SyncRequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= APPROVE =================
  Future<void> applySync(SyncRequest request) async {
    final inventoryCtrl = InventoryController();
    final txCtrl = InventoryTransactionController();

    // ================= 1️⃣ ENSURE ITEMS EXIST =================
    final Map<String, String> itemIdMap = {};

    for (final item in request.inventory) {
      final onlineItemId = await inventoryCtrl.syncEnsureItem(
        name: item['name'],
        category: item['category'],
      );

      itemIdMap[item['id']] = onlineItemId;
    }

    // ================= 2️⃣ APPLY TRANSACTIONS SAFELY =================
    for (final tx in request.transactions) {
      final onlineItemId = itemIdMap[tx['itemId']];
      if (onlineItemId == null) continue;

      final mappedTx = InventoryTransaction.fromMap({
        ...tx,
        'itemId': onlineItemId,
      });

      if (mappedTx.type == TransactionType.dispense) {
        await inventoryCtrl.dispenseWithExcessHandling(
          itemId: onlineItemId,
          quantity: mappedTx.quantity!,
          userName: request.userName,
        );
      } else {
        await inventoryCtrl.applyOfflineTransaction(tx: mappedTx);
      }
    }

    // ================= 3️⃣ LOG TRANSACTIONS =================
    await txCtrl.syncAll(
      request.transactions.map((tx) {
        final onlineItemId = itemIdMap[tx['itemId']];
        if (onlineItemId == null) return null;

        return InventoryTransaction.fromMap({
          ...tx,
          'itemId': onlineItemId,
          'userName': request.userName +" (Offline Sync)",
        });
      }).whereType<InventoryTransaction>().toList(),
    );

    // ================= 4️⃣ MARK APPROVED =================
    await _firestore
        .collection('syncRequests')
        .doc(request.id)
        .update({
      'status': 'approved',
      'approvedAt': Timestamp.now(),
    });
  }





  Future<void> _handleExcessSync({
    required InventoryController inventoryCtrl,
    required InventoryTransaction tx,
  }) async {
    final itemSnap = await FirebaseFirestore.instance
        .collection('items')
        .doc(tx.itemId)
        .get();

    if (!itemSnap.exists) return;

    final data = itemSnap.data()!;
    final List batches = data['batches'] ?? [];

    final int availableStock = batches.fold<int>(
      0,
          (sum, b) => sum + (b['quantity'] as num).toInt(),
    );

    if (availableStock <= 0) {
      // ❌ Nothing to dispense online
      debugPrint(
        '⚠️ [SYNC] No stock online for ${tx.itemName}, skipping dispense',
      );
      return;
    }

    final int dispenseQty = availableStock.clamp(0, tx.quantity!);

    // ✅ Dispense ONLY what exists online
    await inventoryCtrl.dispenseStock(
      itemId: tx.itemId,
      quantity: dispenseQty,
    );

    debugPrint(
      '⚠️ [SYNC] Partial dispense: $dispenseQty / ${tx.quantity} for ${tx.itemName}',
    );
  }



  // ================= REJECT =================
  Future<void> rejectSync(SyncRequest request) async {
    final ref = _firestore
        .collection('syncRequests')
        .doc(request.id);

    // ❌ Reject = DELETE ENTIRE REQUEST
    await ref.delete();
  }
}
