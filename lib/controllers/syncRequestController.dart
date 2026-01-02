import 'package:cloud_firestore/cloud_firestore.dart';
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
      final itemId = await inventoryCtrl.syncEnsureItem(
        name: item['name'],
        category: item['category'],
      );

      itemIdMap[item['id']] = itemId;
    }

    // ================= 2️⃣ APPLY STOCK CHANGES =================
    for (final tx in request.transactions) {
      final originalItemId = tx['itemId'];
      final onlineItemId = itemIdMap[originalItemId];

      if (onlineItemId == null) continue;

      final offlineTx = InventoryTransaction.fromMap({
        ...tx,
        'itemId': onlineItemId,
      });

      await inventoryCtrl.applyOfflineTransaction(tx: offlineTx);
    }

    // ================= 3️⃣ LOG TRANSACTIONS =================
    await txCtrl.syncAll(
      request.transactions
          .map((e) => InventoryTransaction.fromMap(e))
          .toList(),
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

  // ================= REJECT =================
  Future<void> rejectSync(SyncRequest request) async {
    final ref = _firestore
        .collection('syncRequests')
        .doc(request.id);

    // ❌ Reject = DELETE ENTIRE REQUEST
    await ref.delete();
  }
}
