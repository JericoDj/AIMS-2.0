import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/SyncRequestModel.dart';
import '../models/TransactionModel.dart';
import '../providers/accounts_provider.dart';
import 'inventoryController.dart';
import 'inventoryTransactionController.dart';

class SyncRequestController {

  final AccountsProvider _accountsProvider;
  SyncRequestController(this._accountsProvider);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // ================= APPROVE =================
  Future<void> applySync(SyncRequest request) async {

    print('✅ Applying sync for request id: ${request.id}');



    final inventoryCtrl = InventoryController();
    final txCtrl = InventoryTransactionController();

    final approverName =
        _accountsProvider.currentUser?.fullName ?? 'Unknown Approver';

    // ================= 1️⃣ ENSURE ITEMS EXIST =================
    final Map<String, String> itemIdMap = {};
    print('🔄 Ensuring declarations');

    for (final item in request.inventory) {
      try {
        final name = item['name'];
        final category = item['category'];

        if (name == null || category == null) {
          debugPrint('⚠️ Skipping invalid item: $item');
          continue;
        }

        debugPrint('🔄 Syncing item: $name');

        final onlineItemId = await inventoryCtrl.syncEnsureItem(
          name: name,
          category: category,
        );

        itemIdMap[item['id']] = onlineItemId;

        debugPrint('✅ Item synced: $name → $onlineItemId');
      } catch (e, s) {
        debugPrint('❌ Failed syncing item: ${item['name']}');
        debugPrint('❌ Error: $e');
        debugPrintStack(stackTrace: s);

        // 🚨 DO NOT STOP THE WHOLE SYNC
        continue;
      }
    }


    print('done first part');
    // ================= 2️⃣ APPLY TRANSACTIONS SAFELY =================
    for (final tx in request.transactions) {
      try {
        debugPrint('➡️ Applying tx: ${tx['id'] ?? tx['type']}');

        final onlineItemId = itemIdMap[tx['itemId']];
        if (onlineItemId == null) {
          debugPrint('⚠️ Skipped tx, itemId not mapped: ${tx['itemId']}');
          continue;
        }

        final mappedTx = InventoryTransaction.fromMap({
          ...tx,
          'itemId': onlineItemId,
          'approvedBy': approverName,
        });

        // 🔒 SAFETY CHECK
        if (mappedTx.quantity == null || mappedTx.quantity! <= 0) {
          debugPrint('⚠️ Invalid quantity for tx ${mappedTx.id}');
          continue;
        }

        if (mappedTx.type == TransactionType.dispense) {
          debugPrint('🔴 Dispense ${mappedTx.quantity} of $onlineItemId');

          await inventoryCtrl.dispenseWithExcessHandling(
            itemId: onlineItemId,
            quantity: mappedTx.quantity!,
            userName: request.userName,
          );
        } else {
          debugPrint('🟢 Apply tx ${mappedTx.type}');

          await inventoryCtrl.applyOfflineTransaction(
            tx: mappedTx,
          );
        }

        debugPrint('✅ Tx applied');
      } catch (e, s) {
        debugPrint('❌ TX FAILED: ${tx.toString()}');
        debugPrint('❌ Error: $e');
        debugPrintStack(stackTrace: s);

        // 🚨 IMPORTANT: continue, never crash sync
        continue;
      }
    }
    print('done second part');

    // ================= 3️⃣ LOG TRANSACTIONS =================
    // ================= 3️⃣ LOG TRANSACTIONS =================
    await txCtrl.syncAll(
      request.transactions.map((tx) {
        final onlineItemId = itemIdMap[tx['itemId']];
        if (onlineItemId == null) return null;

        return InventoryTransaction.fromMap({
          ...tx,
          'itemId': onlineItemId,
          'userName': '${request.userName} (Offline Sync)',
          'approvedBy': approverName,
          'approvedAt': Timestamp.now(),
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
      'approvedBy': approverName,
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
    await inventoryCtrl.dispenseStockNoLogs(
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
