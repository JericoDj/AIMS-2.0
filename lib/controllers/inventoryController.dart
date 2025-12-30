import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';


import '../models/BarcodePngResult.dart';
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
    debugPrint('🟢 [addStock] START (NO TRANSACTION)');

    final ref = _firestore.collection('items').doc(itemId);
    String itemName = '';

    try {
      debugPrint('🟡 [addStock] Fetching item document');

      final snap = await ref.get();

      if (!snap.exists) {
        debugPrint('⚠️ [addStock] Item does not exist');
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      itemName = data['name'] ?? '';

      final List<Map<String, dynamic>> batches =
      List<Map<String, dynamic>>.from(data['batches'] ?? []);

      final expiryKey = expiry.toIso8601String();

      final index = batches.indexWhere(
            (b) => b['expiry'] == expiryKey,
      );

      if (index != -1) {
        final oldQty = (batches[index]['quantity'] as num).toInt();
        batches[index]['quantity'] = oldQty + quantity;
      } else {
        batches.add({
          'quantity': quantity,
          'expiry': expiryKey,
        });
      }

      debugPrint('🟡 [addStock] Updating document');

      await ref.update({
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('🟢 [addStock] Document updated successfully');
    } catch (e, s) {
      debugPrint('❌ [addStock] FAILED: $e');
      debugPrintStack(stackTrace: s);
      return;
    }

    // Logging (still isolated)
    try {
      await InventoryTransactionController().log(
        type: TransactionType.addStock,
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
        expiry: expiry,
      );
      debugPrint('🟢 [addStock] Transaction logged');
    } catch (e) {
      debugPrint('⚠️ [addStock] Logging failed: $e');
    }

    debugPrint('🟢 [addStock] END');
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
        debugPrint('🟡 [dispenseStock] Fetching item document');

        final snap = await tx.get(ref);

        if (!snap.exists) {
          throw Exception('Item does not exist');
        }

        final data = snap.data() as Map<String, dynamic>;
        itemName = data['name'] ?? '';

        List<Map<String, dynamic>> batches =
        List<Map<String, dynamic>>.from(data['batches'] ?? []);

        // FIFO → earliest expiry first
        batches.sort(
              (a, b) => DateTime.parse(a['expiry'])
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

        debugPrint('🟡 [dispenseStock] Updating document');

        tx.update(ref, {
          'batches': batches,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('🟢 [dispenseStock] Document updated successfully');
    } catch (e, s) {
      debugPrint('❌ [dispenseStock] FAILED: $e');
      debugPrintStack(stackTrace: s);
      rethrow; // let UI show error (insufficient stock etc.)
    }

    // ================= LOGGING (ISOLATED) =================
    try {
      await InventoryTransactionController().log(
        type: TransactionType.dispense,
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
      );
      debugPrint('🟢 [dispenseStock] Transaction logged');
    } catch (e) {
      debugPrint('⚠️ [dispenseStock] Logging failed: $e');
    }

    debugPrint('🔴 [dispenseStock] END');
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