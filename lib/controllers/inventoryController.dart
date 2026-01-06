import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';


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

    String itemName = '';
    int excess = 0;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      itemName = data['name'] ?? '';

      List<Map<String, dynamic>> batches =
      List<Map<String, dynamic>>.from(data['batches'] ?? []);

      batches.sort((a, b) =>
          DateTime.parse(a['expiry']).compareTo(DateTime.parse(b['expiry'])));

      int available = batches.fold(
        0,
            (sum, b) => sum + (b['quantity'] as num).toInt(),
      );

      int toConsume = quantity > available ? available : quantity;
      excess = quantity - toConsume;

      int remaining = toConsume;

      for (final b in batches) {
        if (remaining <= 0) break;

        final q = (b['quantity'] as num).toInt();
        if (q <= remaining) {
          remaining -= q;
          b['quantity'] = 0;
        } else {
          b['quantity'] = q - remaining;
          remaining = 0;
        }
      }

      batches.removeWhere((b) => (b['quantity'] as num).toInt() == 0);

      tx.update(ref, {
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔴 TRACK EXCESS (AUDIT ONLY)
      if (excess > 0) {
        tx.update(ref, {
          'excessUsage': FieldValue.increment(excess),
        });
      }
    });

    // ✅ LOG FULL OFFLINE INTENT
    // await InventoryTransactionController().log(
    //   type: TransactionType.dispense,
    //   itemId: itemId,
    //   itemName: itemName,
    //   quantity: quantity,
    //   userName: userName,
    //
    // );

    if (excess > 0) {
      debugPrint(
        '⚠️ [SYNC] Excess $excess recorded for $itemName',
      );
    }
  }


  // ================= CREATE =================
  Future<String> createItem({
    required String name,
    required String category,
  }) async {
    debugPrint('🧾 Creating item: $name');

    // ============================
    // 1️⃣ Create Firestore item
    // ============================
    final DocumentReference docRef =
    await _firestore.collection('items').add({
      'name': name,
      'name_key': normalizeItemName(name),
      'category': category,
      'batches': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String itemId = docRef.id;

    // // ============================
    // // 2️⃣ Generate Code128 barcode
    // // ============================
    // final BarcodePngResult barcodeResult =
    // BarcodeController.generateCode128(name);
    //
    // final Uint8List barcodePngBytes = barcodeResult.pngBytes;

    // ============================
// 3️⃣ Generate QR CODE (Encrypted Item ID)
// ============================
//     final String encryptedPayload =
//     BarcodeController.generate(itemId);

    final Uint8List qrPngBytes =
    await BarcodeController.generateQrPng(name);

    // ============================
    // 3️⃣ Upload barcode to Storage
    // ============================
    final Reference barcodeRef =
    _storage.ref('items/$itemId/barcode.png');

    await barcodeRef.putData(
      qrPngBytes,
      SettableMetadata(contentType: 'image/png'),
    );

    // ============================
    // 4️⃣ Save barcode image URL
    // ============================
    final String barcodeImageUrl =
    await barcodeRef.getDownloadURL();

    await docRef.update({
      'barcode_image_url': barcodeImageUrl,
    });

    // ============================
    // 5️⃣ Log inventory transaction
    // ============================
    await InventoryTransactionController().log(
      type: TransactionType.createItem,
      itemId: itemId,
      itemName: name,
    );

    return itemId;
  }


  // ================= CREATE =================
  Future<String> createItemNoLogs({
    required String name,
    required String category,
  }) async {
    debugPrint('🧾 Creating item: $name');

    // ============================
    // 1️⃣ Create Firestore item
    // ============================
    final DocumentReference docRef =
    await _firestore.collection('items').add({
      'name': name,
      'name_key': normalizeItemName(name),
      'category': category,
      'batches': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String itemId = docRef.id;

    // // ============================
    // // 2️⃣ Generate Code128 barcode
    // // ============================
    // final BarcodePngResult barcodeResult =
    // BarcodeController.generateCode128(name);
    //
    // final Uint8List barcodePngBytes = barcodeResult.pngBytes;

    // ============================
// 3️⃣ Generate QR CODE (Encrypted Item ID)
// ============================
//     final String encryptedPayload =
//     BarcodeController.generate(itemId);

    final Uint8List qrPngBytes =
    await BarcodeController.generateQrPng(name);

    // ============================
    // 3️⃣ Upload barcode to Storage
    // ============================
    final Reference barcodeRef =
    _storage.ref('items/$itemId/barcode.png');

    await barcodeRef.putData(
      qrPngBytes,
      SettableMetadata(contentType: 'image/png'),
    );

    // ============================
    // 4️⃣ Save barcode image URL
    // ============================
    final String barcodeImageUrl =
    await barcodeRef.getDownloadURL();

    await docRef.update({
      'barcode_image_url': barcodeImageUrl,
    });

    // // ============================
    // // 5️⃣ Log inventory transaction
    // // ============================
    // await InventoryTransactionController().log(
    //   type: TransactionType.createItem,
    //   itemId: itemId,
    //   itemName: name,
    // );

    return itemId;
  }




  Future<bool> itemNameExists(String name) async {
    final snapshot = await _firestore
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
  }) async {
    debugPrint('🟢 [addStock] START');

    final ref = _firestore.collection('items').doc(itemId);
    String itemName = '';

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;

        final data = snap.data()!;
        itemName = data['name'] ?? '';

        final int excessUsage = (data['excessUsage'] ?? 0) as int;
        final int oldMaxStock = (data['maxStock'] ?? 0) as int;

        List<Map<String, dynamic>> batches =
        List<Map<String, dynamic>>.from(data['batches'] ?? []);

        int remainingQty = quantity;

        // 🔴 PAY OFF EXISTING DEBT FIRST
        if (excessUsage > 0) {
          final usedForDebt = remainingQty.clamp(0, excessUsage);
          remainingQty -= usedForDebt;

          tx.update(ref, {
            'excessUsage': FieldValue.increment(-usedForDebt),
          });
        }

        // 🟢 ADD REMAINING STOCK
        if (remainingQty > 0) {
          final expiryKey = expiry.toIso8601String();
          final index =
          batches.indexWhere((b) => b['expiry'] == expiryKey);

          if (index != -1) {
            batches[index]['quantity'] =
                (batches[index]['quantity'] as num).toInt() + remainingQty;
          } else {
            batches.add({
              'quantity': remainingQty,
              'expiry': expiryKey,
            });
          }
        }

        // 📊 CALCULATE TOTAL STOCK AFTER ADD
        final int totalStock =
        batches.fold(0, (sum, b) => sum + (b['quantity'] as num).toInt());

        // 📈 UPDATE MAX STOCK (ONLY IF GROWN)
        final int newMaxStock =
        totalStock > oldMaxStock ? totalStock : oldMaxStock;

        // 🎯 AUTO LOW-STOCK THRESHOLD (50%)
        final int autoThreshold = (newMaxStock * 0.5).round();

        tx.update(ref, {
          'batches': batches,
          'maxStock': newMaxStock,
          'lowStockThreshold': autoThreshold,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('🟢 [addStock] Completed with debt + threshold update');
    } catch (e, s) {
      debugPrint('❌ [addStock] FAILED: $e');
      debugPrintStack(stackTrace: s);
      return;
    }

    // ✅ LOG TRANSACTION
    try {
      await InventoryTransactionController().log(
        type: TransactionType.addStock,
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
        expiry: expiry,
      );
    } catch (e) {
      debugPrint('⚠️ Logging failed: $e');
    }

    debugPrint('🟢 [addStock] END');
  }




  Future<void> addStockNoLogs({
    required String itemId,
    required int quantity,
    required DateTime expiry,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final int excessUsage = (data['excessUsage'] ?? 0) as int;
      final int oldMaxStock = (data['maxStock'] ?? 0) as int;

      List<Map<String, dynamic>> batches =
      List<Map<String, dynamic>>.from(data['batches'] ?? []);

      int remainingQty = quantity;

      // 🔴 PAY OFF DEBT FIRST
      if (excessUsage > 0) {
        final usedForDebt = remainingQty.clamp(0, excessUsage);
        remainingQty -= usedForDebt;

        tx.update(ref, {
          'excessUsage': FieldValue.increment(-usedForDebt),
        });
      }

      // 🟢 ADD STOCK
      if (remainingQty > 0) {
        final expiryKey = expiry.toIso8601String();
        final index =
        batches.indexWhere((b) => b['expiry'] == expiryKey);

        if (index != -1) {
          batches[index]['quantity'] =
              (batches[index]['quantity'] as num).toInt() + remainingQty;
        } else {
          batches.add({
            'quantity': remainingQty,
            'expiry': expiryKey,
          });
        }
      }

      // 📊 TOTAL STOCK
      final int totalStock =
      batches.fold(0, (sum, b) => sum + (b['quantity'] as num).toInt());

      // 📈 MAX STOCK
      final int newMaxStock =
      totalStock > oldMaxStock ? totalStock : oldMaxStock;

      // 🎯 50% THRESHOLD
      final int autoThreshold = (newMaxStock * 0.5).round();

      tx.update(ref, {
        'batches': batches,
        'maxStock': newMaxStock,
        'lowStockThreshold': autoThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }





  // ================= DISPENSE STOCK (FIFO, SAFE) =================
  Future<void> dispenseStock({
    required String itemId,
    required int quantity,
  }) async {
    debugPrint('🔴 [dispenseStock] START');

    final ref = _firestore.collection('items').doc(itemId);
    String itemName = '';

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('Item does not exist');
        }

        final data = snap.data()!;
        itemName = data['name'] ?? '';

        List<Map<String, dynamic>> batches =
        List<Map<String, dynamic>>.from(data['batches'] ?? []);

        // FIFO by expiry
        batches.sort(
              (a, b) => DateTime.parse(a['expiry'])
              .compareTo(DateTime.parse(b['expiry'])),
        );

        int remaining = quantity;

        // 🟢 USE REAL STOCK FIRST
        for (final b in batches) {
          if (remaining <= 0) break;

          final int q = (b['quantity'] as num).toInt();
          if (q <= remaining) {
            remaining -= q;
            b['quantity'] = 0;
          } else {
            b['quantity'] = q - remaining;
            remaining = 0;
          }
        }

        // Remove empty batches
        batches.removeWhere(
              (b) => (b['quantity'] as num).toInt() == 0,
        );

        // 🔴 RECORD DEBT IF NEEDED
        if (remaining > 0) {
          tx.update(ref, {
            'excessUsage': FieldValue.increment(remaining),
          });
        }

        // ⚠️ DO NOT TOUCH maxStock / threshold
        tx.update(ref, {
          'batches': batches,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('🟢 [dispenseStock] Completed with debt support');
    } catch (e, s) {
      debugPrint('❌ [dispenseStock] FAILED: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }

    // ✅ LOG TRANSACTION
    try {
      await InventoryTransactionController().log(
        type: TransactionType.dispense,
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
      );
    } catch (e) {
      debugPrint('⚠️ Logging failed: $e');
    }

    debugPrint('🔴 [dispenseStock] END');
  }



  Future<void> dispenseStockNoLogs({
    required String itemId,
    required int quantity,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      List<Map<String, dynamic>> batches =
      List<Map<String, dynamic>>.from(data['batches'] ?? []);

      // FIFO by expiry
      batches.sort(
            (a, b) => DateTime.parse(a['expiry'])
            .compareTo(DateTime.parse(b['expiry'])),
      );

      int remaining = quantity;

      // 🟢 USE REAL STOCK FIRST
      for (final b in batches) {
        if (remaining <= 0) break;

        final int q = (b['quantity'] as num).toInt();
        if (q <= remaining) {
          remaining -= q;
          b['quantity'] = 0;
        } else {
          b['quantity'] = q - remaining;
          remaining = 0;
        }
      }

      // Remove empty batches
      batches.removeWhere(
            (b) => (b['quantity'] as num).toInt() == 0,
      );

      // 🔴 RECORD DEBT
      if (remaining > 0) {
        tx.update(ref, {
          'excessUsage': FieldValue.increment(remaining),
        });
      }

      // ⚠️ DO NOT TOUCH maxStock / threshold
      tx.update(ref, {
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }


  Future<String?> findItemIdByName(String name) async {
    final key = normalizeItemName(name);

    final snap = await _firestore
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
    final existingId = await findItemIdByName(name);
    if (existingId != null) return existingId;

    // Create item ONLY if missing
    return await createItemNoLogs(
      name: name,
      category: category,
    );
  }

  Future<void> applyOfflineTransaction({
    required InventoryTransaction tx,
  }) async {
    switch (tx.type) {
      case TransactionType.addStock:
        await addStockNoLogs(
          itemId: tx.itemId,
          quantity: tx.quantity!,
          expiry: tx.expiry!,

        );
        break;

      case TransactionType.dispense:
        await dispenseStockNoLogs(
          itemId: tx.itemId,
          quantity: tx.quantity!,

        );
        break;

      case TransactionType.createItem:
      case TransactionType.deleteItem:
      // ❌ IGNORE — handled separately
        break;
    }
  }









  // ================= FIFO TRANSACTION =================
  Future<void> transactStockFIFO({
    required String itemId,
    required int quantity,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    String itemName = '';

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;

      itemName = data['name']; // capture for logging

      List<Map<String, dynamic>> batches =
      List<Map<String, dynamic>>.from(data['batches']);

      // FIFO → sort by expiry
      batches.sort(
            (a, b) =>
            DateTime.parse(a['expiry'])
                .compareTo(DateTime.parse(b['expiry'])),
      );

      int remaining = quantity;

      for (int i = 0; i < batches.length && remaining > 0; i++) {
        final int batchQty = (batches[i]['quantity'] as num).toInt();

        if (batchQty <= remaining) {
          remaining -= batchQty;
          batches[i]['quantity'] = 0;
        } else {
          batches[i]['quantity'] = batchQty - remaining;
          remaining = 0;
        }
      }

      if (remaining > 0) {
        throw Exception('Insufficient stock');
      }

      // Remove empty batches
      batches.removeWhere(
            (b) => (b['quantity'] as num).toInt() == 0,
      );

      tx.update(ref, {
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // ✅ LOG DISPENSE ACTION
    await InventoryTransactionController().log(
      type: TransactionType.dispense,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
    );
  }


  // ================= DELETE =================
  Future<void> deleteItem({
    required String itemId,
    required String itemName,
  }) async {
    await _firestore.collection('items').doc(itemId).delete();

    // ✅ LOG DELETE
    await InventoryTransactionController().log(
      type: TransactionType.deleteItem,
      itemId: itemId,
      itemName: itemName,
    );
  }
}