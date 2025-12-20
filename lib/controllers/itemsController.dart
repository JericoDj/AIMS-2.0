import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= CREATE =================
  Future<void> createItem({
    required String name,
    required String category,
  }) async {
    await _firestore.collection('items').add({
      'name': name,
      'category': category,
      'batches': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= ADD STOCK (STACK BY EXPIRY) =================
  Future<void> addStock({
    required String itemId,
    required int quantity,
    required DateTime expiry,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;
      List batches = List.from(data['batches']);

      final expiryKey = expiry.toIso8601String();

      final index =
      batches.indexWhere((b) => b['expiry'] == expiryKey);

      if (index != -1) {
        batches[index]['quantity'] += quantity;
      } else {
        batches.add({
          'quantity': quantity,
          'expiry': expiryKey,
        });
      }

      tx.update(ref, {
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ================= FIFO TRANSACTION =================
  Future<void> transactStockFIFO({
    required String itemId,
    required int quantity,
  }) async {
    final ref = _firestore.collection('items').doc(itemId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;
      List<Map<String, dynamic>> batches =
      List<Map<String, dynamic>>.from(data['batches']);

      // Sort by expiry (FIFO)
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

      tx.update(ref, {
        'batches': batches,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ================= DELETE =================
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }
}
