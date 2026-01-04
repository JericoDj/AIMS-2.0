import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/ItemModel.dart';
import 'notification_provider.dart';



class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int _limit = 20;
  final List<ItemModel> _items = [];

  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  List<ItemModel> get items => _items;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  // ================= FETCH =================
  Future<void> fetchItems({
    bool refresh = false,
    BuildContext? context, // 👈 pass context ONCE
  }) async {
    if (_loading) return;

    if (refresh) {
      _items.clear();
      _lastDoc = null;
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore) return;

    _loading = true;
    notifyListeners();

    Query query = _firestore
        .collection('items')
        .orderBy('name')
        .limit(_limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;

      final fetchedItems = snapshot.docs
          .map((e) => ItemModel.fromFirestore(e))
          .toList();

      _items.addAll(fetchedItems);

      // 🔔 TRIGGER NOTIFICATION CHECK (SAFE)
      if (context != null) {
        await _handleLowStockNotifications(fetchedItems, context);
      }
    }

    if (snapshot.docs.length < _limit) {
      _hasMore = false;
    }

    _loading = false;
    notifyListeners();
  }


  // ================= HELPERS =================
  int get totalItemCount => _items.length;

  int get totalStock =>
      _items.fold(0, (sum, item) => sum + item.totalStock);

  List<ItemModel> get lowStockItems =>
      _items.where((i) => i.isLowStock).toList();

  List<ItemModel> get nearlyExpiredItems {
    final now = DateTime.now();
    return _items.where((item) {
      return item.batches.any(
            (b) => b.expiry.difference(now).inDays <= 30,
      );
    }).toList();
  }



  Future<void> checkAndSendStockNotifications(
      NotificationProvider notifProvider,
      ) async {

    print("checked and sending stock notifications");
    print("total items: ${_items.length}");
    print(_items.map((e) => e.name).toList());
    const adminEmail = 'dejesusjerico528@gmail.com';
    const emailEndpoint =
        'https://sendinventoryalert-tekpv2phba-uc.a.run.app';

    for (final item in _items) {
      // 🔔 LOW STOCK — SEND ONCE
      if (item.isLowStock && !item.lowStockNotified) {
        // 1️⃣ Mark as notified FIRST
        await _firestore.collection('items').doc(item.id).update({
          'lowStockNotified': true,
        });

        // 2️⃣ In-app notification
        await notifProvider.createNotification(
          itemId: item.id,
          itemName: item.name,
          type: 'LOW_STOCK',
          message:
          '${item.name} is low on stock (${item.totalStock} remaining)',
        );

        // 3️⃣ Email to admin
        try {
          final res = await http.post(
            Uri.parse(emailEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'to': adminEmail,
              'type': 'LOW_STOCK',
              'itemName': item.name,
              'message':
              '${item.name} is low on stock (${item.totalStock} remaining)',
            }),
          );

          if (res.statusCode != 200) {
            debugPrint('❌ Email API failed: ${res.body}');
          }
        } catch (e) {
          debugPrint('❌ Email request error: $e');
        }
      }

      // 🔄 RESET FLAG WHEN STOCK RECOVERS
      if (!item.isLowStock && item.lowStockNotified) {
        await _firestore.collection('items').doc(item.id).update({
          'lowStockNotified': false,
        });
      }
    }
  }




  Future<void> updateLowStockThreshold({
    required String itemId,
    required int value,
  }) async {
    await _firestore.collection('items').doc(itemId).update({
      'lowStockThreshold': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        lowStockThreshold: value,
      );
      notifyListeners();
    }
  }


  Future<void> _handleLowStockNotifications(
      List<ItemModel> items,
      BuildContext context,
      ) async {
    final notifProvider = context.read<NotificationProvider>();

    for (final item in items) {
      // 🔔 LOW STOCK TRIGGER
      if (item.isLowStock && !item.lowStockNotified) {
        await _firestore.collection('items').doc(item.id).update({
          'lowStockNotified': true,
        });

        await notifProvider.createNotification(
          itemId: item.id,
          itemName: item.name,
          type: 'LOW_STOCK',
          message:
          '${item.name} is low on stock (${item.totalStock} remaining)',
        );
      }

      // 🔄 RESET FLAG WHEN STOCK RECOVERS
      if (!item.isLowStock && item.lowStockNotified) {
        await _firestore.collection('items').doc(item.id).update({
          'lowStockNotified': false,
        });
      }
    }
  }





}
