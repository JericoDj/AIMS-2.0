import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../models/AccountModel.dart';
import '../models/BarcodePngResult.dart';
import '../models/SyncRequestModel.dart';
import '../models/TransactionModel.dart';
import 'barCodeController.dart';
import 'barCodeDecoderController.dart';
import 'inventoryTransactionController.dart';

class InventoryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String normalizeItemName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '') // remove spaces & symbols
        .trim();
  }

  Future<void> dispenseWithExcessHandling({
    required String itemId,
    required int quantity,
    required String userName,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    try {
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final String itemName = data['name'] ?? '';

      final List<Map<String, dynamic>> batches =
          List<Map<String, dynamic>>.from(data['batches'] ?? []);

      // 🔁 Sort FIFO by expiry (safe — local copy)
      batches.sort(
        (a, b) =>
            DateTime.parse(a['expiry']).compareTo(DateTime.parse(b['expiry'])),
      );

      int available = batches.fold(
        0,
        (sum, b) => sum + (b['quantity'] as num).toInt(),
      );

      final int toConsume = quantity > available ? available : quantity;
      final int excess = quantity - toConsume;

      int remaining = toConsume;

      final List<Map<String, dynamic>> updatedBatches = [];

      for (final b in batches) {
        final int q = (b['quantity'] as num).toInt();

        if (remaining <= 0) {
          // untouched batch
          updatedBatches.add(b);
          continue;
        }

        if (q <= remaining) {
          remaining -= q;
          // batch fully consumed → skip
        } else {
          updatedBatches.add({...b, 'quantity': q - remaining});
          remaining = 0;
        }
      }

      // 🔧 Build update payload once
      final Map<String, dynamic> updatePayload = {
        'batches': updatedBatches,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (excess > 0) {
        updatePayload['excessUsage'] = (data['excessUsage'] ?? 0) + excess;
      }

      // ✅ SINGLE UPDATE — WINDOWS SAFE
      await ref.update(updatePayload);

      if (excess > 0) {
        debugPrint('⚠️ [SYNC] Excess $excess recorded for $itemName');
      }
    } catch (e, s) {
      debugPrint('❌ dispenseWithExcessHandling FAILED: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // ================= CREATE =================
  Future<String> createItem({
    required String name,
    required String category,
    required Account? user,
  }) async {
    debugPrint('🧾 Creating item: $name');

    // ============================
    // 1️⃣ Create Firestore item
    // ============================
    final DocumentReference docRef = await _firestore.collection('items').add({
      'name': name,
      'name_key': normalizeItemName(name),
      'category': category,
      'batches': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String itemId = docRef.id;

    // 🔑 Yield back to platform thread (WINDOWS FIX)
    await Future.delayed(const Duration(milliseconds: 20));

    // ============================
    // 2️⃣ Generate QR CODE
    // ============================
    final Uint8List qrPngBytes = await BarcodeController.generateQrPng(name);

    // ============================
    // 3️⃣ Upload barcode to Storage
    // ============================
    final Reference barcodeRef = _storage.ref('items/$itemId/barcode.png');

    await barcodeRef.putData(
      qrPngBytes,
      SettableMetadata(contentType: 'image/png'),
    );

    // 🔑 Yield again after native upload
    await Future.delayed(const Duration(milliseconds: 20));

    // ============================
    // 4️⃣ Save barcode image URL
    // ============================
    final String barcodeImageUrl = await barcodeRef.getDownloadURL();

    await docRef.update({'barcode_image_url': barcodeImageUrl});

    // ============================
    // 5️⃣ Log inventory transaction (SAFE)
    // ============================
    Future.microtask(() async {
      try {
        await InventoryTransactionController().log(
          type: TransactionType.createItem,
          itemId: itemId,
          itemName: name,
          user: user,
        );
      } catch (e) {
        debugPrint('⚠️ Log failed: $e');
      }
    });

    return itemId;
  }

  // ================= CREATE =================
  Future<String> createItemNoLogs({
    required String name,
    required String category,
  }) async {
    debugPrint('🧾 Creating item: $name');

    final docRef = await _firestore.collection('items').add({
      'name': name,
      'name_key': normalizeItemName(name),
      'category': category,
      'batches': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final itemId = docRef.id;

    try {
      final Uint8List qrPngBytes = await BarcodeController.generateQrPng(name);

      final barcodeRef = _storage.ref('items/$itemId/barcode.png');

      await barcodeRef.putData(
        qrPngBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final barcodeImageUrl = await barcodeRef.getDownloadURL();

      await docRef.update({'barcode_image_url': barcodeImageUrl});
    } catch (e, s) {
      debugPrint('⚠️ Barcode generation/upload failed: $e');
      debugPrintStack(stackTrace: s);
      // item still exists — UI can retry barcode later
    }

    return itemId;
  }

  Future<bool> itemNameExists(String name) async {
    final snapshot =
        await _firestore
            .collection('items')
            .where('name_key', isEqualTo: normalizeItemName(name))
            .limit(1)
            .get();

    debugPrint('🔍 itemNameExists("${name.toLowerCase()}")');
    debugPrint('📦 docs length: ${snapshot.docs.length}');

    if (snapshot.docs.isNotEmpty) {
      debugPrint('❗ Existing item ID: ${snapshot.docs.first.id}');
    }

    return snapshot.docs.isNotEmpty;
  }

  // ================= ADD STOCK (STACK BY EXPIRY) =================
  Future<void> addStock({
    required String itemId,
    required int quantity,
    required DateTime expiry,
    required Account? user,
  }) async {
    debugPrint('🟢 [addStock] START');

    if (quantity <= 0) return;

    final ref = _firestore.collection('items').doc(itemId);

    try {
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final String itemName = data['name'] ?? '';

      final int excessUsage = (data['excessUsage'] ?? 0) as int;
      final int oldMaxStock = (data['maxStock'] ?? 0) as int;

      final List<Map<String, dynamic>> batches =
          List<Map<String, dynamic>>.from(
            (data['batches'] ?? []).map((e) => Map<String, dynamic>.from(e)),
          );

      int remainingQty = quantity;
      int newExcessUsage = excessUsage;

      // 🔴 PAY OFF DEBT
      if (excessUsage > 0) {
        final usedForDebt = remainingQty.clamp(0, excessUsage);
        remainingQty -= usedForDebt;
        newExcessUsage -= usedForDebt;
      }

      // 🟢 ADD STOCK
      if (remainingQty > 0) {
        final expiryKey = expiry.toIso8601String();
        final index = batches.indexWhere((b) => b['expiry'] == expiryKey);

        if (index != -1) {
          batches[index]['quantity'] =
              (batches[index]['quantity'] as num).toInt() + remainingQty;
        } else {
          batches.add({'quantity': remainingQty, 'expiry': expiryKey});
        }
      }

      final int totalStock = batches.fold(
        0,
        (sum, b) => sum + (b['quantity'] as num).toInt(),
      );

      final int newMaxStock =
          totalStock > oldMaxStock ? totalStock : oldMaxStock;

      final int autoThreshold = (newMaxStock * 0.5).round();

      await ref.update({
        'batches': batches,
        'excessUsage': newExcessUsage,
        'maxStock': newMaxStock,
        'lowStockThreshold': autoThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔑 Let Windows breathe
      await Future.delayed(const Duration(milliseconds: 20));

      // 🔒 LOG WITH EXPLICIT USER
      Future.microtask(() async {
        try {
          await InventoryTransactionController().log(
            type: TransactionType.addStock,
            itemId: itemId,
            itemName: itemName,
            quantity: quantity,
            expiry: expiry,
            user: user,
          );
        } catch (e) {
          debugPrint('⚠️ addStock log failed: $e');
        }
      });

      debugPrint('🟢 [addStock] END');
    } catch (e, s) {
      debugPrint('❌ [addStock] FAILED: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> addStockNoLogs({
    required String itemId,
    required int quantity,
    required DateTime expiry,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    try {
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final int excessUsage = (data['excessUsage'] ?? 0) as int;
      final int oldMaxStock = (data['maxStock'] ?? 0) as int;

      final List<Map<String, dynamic>> batches =
          List<Map<String, dynamic>>.from(data['batches'] ?? []);

      int remainingQty = quantity;
      int newExcessUsage = excessUsage;

      // 🔴 PAY OFF DEBT
      if (newExcessUsage > 0) {
        final usedForDebt = remainingQty.clamp(0, newExcessUsage);
        remainingQty -= usedForDebt;
        newExcessUsage -= usedForDebt;
      }

      // 🟢 ADD STOCK
      if (remainingQty > 0) {
        final expiryKey = expiry.toIso8601String();
        final index = batches.indexWhere((b) => b['expiry'] == expiryKey);

        if (index != -1) {
          batches[index] = {
            ...batches[index],
            'quantity':
                (batches[index]['quantity'] as num).toInt() + remainingQty,
          };
        } else {
          batches.add({'quantity': remainingQty, 'expiry': expiryKey});
        }
      }

      final int totalStock = batches.fold(
        0,
        (sum, b) => sum + (b['quantity'] as num).toInt(),
      );

      final int newMaxStock =
          totalStock > oldMaxStock ? totalStock : oldMaxStock;

      final int autoThreshold = (newMaxStock * 0.5).round();

      // ✅ SINGLE UPDATE — WINDOWS SAFE
      await ref.update({
        'batches': batches,
        'excessUsage': newExcessUsage,
        'maxStock': newMaxStock,
        'lowStockThreshold': autoThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ addStockNoLogs success');
    } catch (e, s) {
      debugPrint('❌ addStockNoLogs FAILED: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  // ================= DISPENSE STOCK (FIFO, SAFE) =================
  Future<void> dispenseStock({
    required String itemId,
    required int quantity,
    required Account? user,
  }) async {
    debugPrint('🔴 [dispenseStock] START');

    final ref = _firestore.collection('items').doc(itemId);

    try {
      final snap = await ref.get();
      if (!snap.exists) {
        throw Exception('Item does not exist');
      }

      final data = snap.data()!;
      final String itemName = data['name'] ?? '';

      List<Map<String, dynamic>> batches = List<Map<String, dynamic>>.from(
        data['batches'] ?? [],
      );

      // FIFO by expiry
      batches.sort(
        (a, b) =>
            DateTime.parse(a['expiry']).compareTo(DateTime.parse(b['expiry'])),
      );

      int remaining = quantity;

      for (final batch in batches) {
        if (remaining <= 0) break;

        final int q = (batch['quantity'] as num).toInt();
        if (q <= remaining) {
          remaining -= q;
          batch['quantity'] = 0;
        } else {
          batch['quantity'] = q - remaining;
          remaining = 0;
        }
      }

      // Remove empty batches
      batches.removeWhere((b) => (b['quantity'] as num).toInt() == 0);

      final Map<String, dynamic> updateData = {
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 🔴 record debt if overdraft
      if (remaining > 0) {
        updateData['excessUsage'] = FieldValue.increment(remaining);
      }

      await ref.update(updateData);

      debugPrint('🟢 [dispenseStock] DB update done');

      // 🔒 async-safe logging
      Future.microtask(() {
        InventoryTransactionController()
            .log(
              type: TransactionType.dispense,
              itemId: itemId,
              itemName: itemName,
              quantity: quantity,
              source: 'ONLINE',
              user: user,
            )
            .catchError((e) {
              debugPrint('⚠️ dispense log failed: $e');
            });
      });

      debugPrint('🔴 [dispenseStock] END');
    } catch (e, s) {
      debugPrint('❌ [dispenseStock] FAILED: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> dispenseStockNoLogs({
    required String itemId,
    required int quantity,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    List<Map<String, dynamic>> batches = List<Map<String, dynamic>>.from(
      data['batches'] ?? [],
    );

    // FIFO by expiry
    batches.sort(
      (a, b) =>
          DateTime.parse(a['expiry']).compareTo(DateTime.parse(b['expiry'])),
    );

    int remaining = quantity;

    for (final batch in batches) {
      if (remaining <= 0) break;

      final int q = (batch['quantity'] as num).toInt();
      if (q <= remaining) {
        remaining -= q;
        batch['quantity'] = 0;
      } else {
        batch['quantity'] = q - remaining;
        remaining = 0;
      }
    }

    // Remove empty batches
    batches.removeWhere((b) => (b['quantity'] as num).toInt() == 0);

    final Map<String, dynamic> updateData = {
      'batches': batches,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 🔴 Record debt if overdraft
    if (remaining > 0) {
      updateData['excessUsage'] = FieldValue.increment(remaining);
    }

    await ref.update(updateData);
  }

  // ================= DELETE ITEM =================
  Future<void> deleteItem({
    required String itemId,
    required String itemName,
    required Account? user,
  }) async {
    debugPrint('🗑️ [deleteItem] Deleting $itemName ($itemId)');

    final ref = _firestore.collection('items').doc(itemId);

    try {
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final List batches = data['batches'] ?? [];

      final int totalStock = batches.fold<int>(
        0,
            (sum, b) => sum + ((b['quantity'] ?? 0) as num).toInt(),
      );

      // ✅ LOG DELETE (MUST AWAIT)
      await InventoryTransactionController().log(
        type: TransactionType.deleteItem,
        itemId: itemId,
        itemName: itemName,
        quantity: totalStock,
        user: user,
      );

      // 🔔 NOTIFICATION
      await createNotification(
        itemId: itemId,
        itemName: itemName,
        type: 'ITEM_DELETED',
        message: 'Item "$itemName" deleted (qty: $totalStock)',
      );

      // 🗑 DELETE ITEM
      await ref.delete();

      // 🧹 DELETE BARCODE
      try {
        await _storage.ref('items/$itemId/barcode.png').delete();
      } catch (_) {}

      debugPrint('✅ [deleteItem] Deleted with qty=$totalStock');
    } catch (e, s) {
      debugPrint('❌ [deleteItem] FAILED: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }


  Future<String?> findItemIdByName(String name) async {
    final key = normalizeItemName(name);

    final snap =
        await _firestore
            .collection('items')
            .where('name_key', isEqualTo: key)
            .limit(1)
            .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<String> syncEnsureItem({
    required String name,
    required String category,
  }) async {
    print('syncEnsureItem: $name in $category');
    final existingId = await findItemIdByName(name);
    if (existingId != null) return existingId;

    // Create item ONLY if missing
    return await createItemNoLogs(name: name, category: category);
  }

  Future<void> applyOfflineTransaction({
    required InventoryTransaction tx,
  }) async {
    try {
      debugPrint('➡️ applyOfflineTransaction START');
      debugPrint(
        'type=${tx.type}, itemId=${tx.itemId}, qty=${tx.quantity}, expiry=${tx.expiry}',
      );

      // ================= ADD STOCK =================
      if (tx.type == TransactionType.addStock) {
        if (tx.quantity == null || tx.expiry == null) {
          debugPrint('⚠️ Skipping addStock — missing quantity or expiry');
          return;
        }

        await addStockNoLogs(
          itemId: tx.itemId,
          quantity: tx.quantity!,
          expiry: tx.expiry!,
        );

        await createNotification(
          itemId: tx.itemId,
          itemName: tx.itemName,
          type: 'STOCK_ADDED',
          message: 'Added ${tx.quantity} pcs to ${tx.itemName}',
        );

        debugPrint('✅ addStock applied (no logs)');
        return;
      }

      // ================= DISPENSE =================
      if (tx.type == TransactionType.dispense) {
        if (tx.quantity == null) {
          debugPrint('⚠️ Skipping dispense — missing quantity');
          return;
        }

        await dispenseStockNoLogs(itemId: tx.itemId, quantity: tx.quantity!);

        await createNotification(
          itemId: tx.itemId,
          itemName: tx.itemName,
          type: 'DISPENSED',
          message: 'Added ${tx.quantity} pcs to ${tx.itemName}',
        );

        debugPrint('✅ dispense applied (no logs)');
        return;
      }

      // ================= IGNORED TYPES =================
      if (tx.type == TransactionType.createItem
      // || tx.type == TransactionType.deleteItem
      ) {
        debugPrint('ℹ️ Ignored tx type: ${tx.type}');
        return;
      }

      debugPrint('⚠️ Unknown tx type: ${tx.type}');
    } catch (e, s) {
      debugPrint('❌ applyOfflineTransaction FAILED');
      debugPrint('TX RAW: ${tx.toJson()}');
      debugPrintStack(stackTrace: s);
      // 🚨 DO NOT rethrow — sync must continue
    }
  }

  Future<void> createNotification({
    required String itemId,
    required String itemName,
    required String type,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'itemId': itemId,
      'itemName': itemName,
      'type': type,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= FIFO TRANSACTION =================
  // Future<void> transactStockFIFO({
  //   required String itemId,
  //   required int quantity,
  //   required Account? user,
  // }) async {
  //   final ref = _firestore.collection('items').doc(itemId);
  //   String itemName = '';
  //
  //   await _firestore.runTransaction((tx) async {
  //     final snap = await tx.get(ref);
  //     if (!snap.exists) {
  //       throw Exception('Item does not exist');
  //     }
  //
  //     final data = snap.data()!;
  //     itemName = data['name'] ?? '';
  //
  //     List<Map<String, dynamic>> batches =
  //     List<Map<String, dynamic>>.from(data['batches'] ?? []);
  //
  //     // FIFO → earliest expiry first
  //     batches.sort(
  //           (a, b) => DateTime.parse(a['expiry'])
  //           .compareTo(DateTime.parse(b['expiry'])),
  //     );
  //
  //     int remaining = quantity;
  //
  //     for (final batch in batches) {
  //       if (remaining <= 0) break;
  //
  //       final int batchQty = (batch['quantity'] as num).toInt();
  //       if (batchQty <= remaining) {
  //         remaining -= batchQty;
  //         batch['quantity'] = 0;
  //       } else {
  //         batch['quantity'] = batchQty - remaining;
  //         remaining = 0;
  //       }
  //     }
  //
  //     if (remaining > 0) {
  //       throw Exception('Insufficient stock');
  //     }
  //
  //     batches.removeWhere(
  //           (b) => (b['quantity'] as num).toInt() == 0,
  //     );
  //
  //     tx.update(ref, {
  //       'batches': batches,
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });
  //   });
  //
  //   // ✅ LOG AFTER TRANSACTION (SAFE)
  //   await InventoryTransactionController().log(
  //     type: TransactionType.dispense,
  //     itemId: itemId,
  //     itemName: itemName,
  //     quantity: quantity,
  //     source: 'ONLINE',
  //     user: user,
  //   );
  // }
}
