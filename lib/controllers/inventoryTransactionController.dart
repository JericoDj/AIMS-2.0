import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as context;

import '../models/AccountModel.dart';
import '../models/TransactionModel.dart';
import '../providers/accounts_provider.dart';
import '../utils/storage_keys.dart';

class InventoryTransactionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _box = GetStorage();

  /// Read current user from storage (safe)
  Map<String, dynamic>? _getCurrentUser() {
    try {
      final raw = _box.read(StorageKeys.currentUser);

      // ✅ Expected case: stored map
      if (raw is Map<String, dynamic>) {
        return raw;
      }

      // ✅ Some GetStorage versions return Map<dynamic, dynamic>
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }

      // ❌ Anything else is invalid
      return null;
    } catch (e) {
      debugPrint('⚠️ _getCurrentUser failed: $e');
      return null;
    }
  }


  /// ================= LOG (ONLINE) =================
  /// ⚠️ MUST NEVER THROW
  Future<void> log({
    required TransactionType type,
    required String itemId,
    required String itemName,
    required Account? user, // 👈 USER IS PASSED IN
    int? quantity,
    DateTime? expiry,
    String source = 'ONLINE',
  }) async {
    debugPrint(
      '🧾 [LOG] userId=${user?.id}, '
          'userName=${user?.fullName}, '
          'role=${user?.role.name}, '
          'source=$source',
    );

    final payload = {
      'type': type.name.toUpperCase(),

      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'expiry': expiry?.toIso8601String(),

      // ✅ DIRECT, RELIABLE USER
      'userId': user?.id,
      'userName': user?.fullName,
      'userRole': user?.role.name,

      'source': source,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('transactions').add(payload);
    } catch (_) {
      // ❗ logging must NEVER break inventory
    }
  }



  /// ================= SYNC (OFFLINE → ONLINE) =================
  Future<void> sync(InventoryTransaction tx) async {
    await _firestore.collection('transactions').add({
      'type': tx.type.name.toUpperCase(),
      'itemId': tx.itemId,
      'itemName': tx.itemName,
      'quantity': tx.quantity,
      'expiry': tx.expiry?.toIso8601String(),
      'userId': tx.userId,
      'userName': tx.userName,
      'userRole': tx.userRole,

      // ✅ ADD THESE
      'approvedBy': tx.approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),

      'source': 'OFFLINE_SYNC',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }



  Future<void> syncAll(List<InventoryTransaction> list) async {
    for (final tx in list) {
      await sync(tx);
    }
  }

  Future<void> delete(String transactionId) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (_) {
      // swallow error – do not crash UI
    }
  }


  /// Ensure role is always a STRING
  String? _safeRole(dynamic role) {
    if (role == null) return null;
    if (role is String) return role;
    if (role is Map && role['name'] != null) return role['name'];
    return role.toString();
  }
}
