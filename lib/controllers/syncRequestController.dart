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


  Future<String?> _findItemByNameKey(String nameKey) async {
    final snap = await _firestore
        .collection('items')
        .where('name_key', isEqualTo: nameKey.toLowerCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }


  // ================= APPROVE =================
  Future<void> applySync(SyncRequest request) async {
    print('✅ Applying sync for request id: ${request.id}');

    final inventoryCtrl = InventoryController();
    final txCtrl = InventoryTransactionController();
    final approverName = _accountsProvider.currentUser?.fullName ?? 'Unknown Approver';

    // ================= 1️⃣ MAP ITEMS via name_key LOOKUP =================
    final Map<String, String> itemIdMap = {};
    print('🔄 Matching items using name_key');

    for (final item in request.inventory) {
      try {
        final rawName = item['name'];
        if (rawName == null) {
          debugPrint('⚠️ Skipping invalid item: $item');
          continue;
        }

        final nameKey = rawName.toString().trim().toLowerCase();
        debugPrint('🔍 lookup name_key: $nameKey');

        final snap = await _firestore
            .collection('items')
            .where('name_key', isEqualTo: nameKey)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          debugPrint('🚫 SKIP — no item match for name_key: $nameKey');
          continue;
        }

        final foundId = snap.docs.first.id;
        itemIdMap[item['id']] = foundId;

        debugPrint('✅ Mapped name_key: $nameKey → $foundId');
      } catch (e, s) {
        debugPrint('❌ lookup failed for ${item['name']}');
        debugPrint('$e');
        debugPrintStack(stackTrace: s);
        continue;
      }
    }

    print('done first part');

    // ================= 2️⃣ APPLY TRANSACTIONS =================
    final List<String> appliedTxIds = [];

    for (final tx in request.transactions) {
      try {
        final onlineItemId = itemIdMap[tx['itemId']];
        if (onlineItemId == null) {
          debugPrint('⚠️ SKIP tx — no mapped item');
          continue;
        }

        final snap = await _firestore.collection('items').doc(onlineItemId).get();
        if (!snap.exists) {
          debugPrint('⚠️ SKIP tx — mapped item missing in DB');
          continue;
        }

        final mappedTx = InventoryTransaction.fromMap({
          ...tx,
          'itemId': onlineItemId,
          'approvedBy': approverName,
        });

        if (mappedTx.quantity == null || mappedTx.quantity! <= 0) {
          debugPrint('⚠️ SKIP tx — invalid qty');
          continue;
        }

        if (mappedTx.type == TransactionType.dispense) {
          await inventoryCtrl.dispenseWithExcessHandling(
            itemId: onlineItemId,
            quantity: mappedTx.quantity!,
            userName: request.userName,
          );
        } else {
          await inventoryCtrl.applyOfflineTransaction(tx: mappedTx);
        }

        appliedTxIds.add(tx['id']);
        debugPrint('✅ Applied tx: ${tx['id']}');
      } catch (e, s) {
        debugPrint('❌ TX FAILED: ${tx.toString()}');
        debugPrint('$e');
        debugPrintStack(stackTrace: s);
        continue;
      }
    }

    print('done second part');

    // ================= 3️⃣ LOG SUCCESSFUL TX =================
    final List<InventoryTransaction> successfulTx = [];

    for (final tx in request.transactions) {
      if (!appliedTxIds.contains(tx['id'])) continue;

      final onlineItemId = itemIdMap[tx['itemId']];
      if (onlineItemId == null) continue;

      successfulTx.add(
        InventoryTransaction.fromMap({
          ...tx,
          'itemId': onlineItemId,
          'userName': '${request.userName} (Offline Sync)',
          'approvedBy': approverName,
          'approvedAt': Timestamp.now(),
        }),
      );
    }

    if (successfulTx.isNotEmpty) {
      await txCtrl.syncAll(successfulTx);
    }

    // ================= 4️⃣ MARK APPROVED =================
    await _firestore.collection('syncRequests').doc(request.id).update({
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
