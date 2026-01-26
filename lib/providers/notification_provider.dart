import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/AppNotification.dart';
class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int _limit = 10; // ✅ start small
  bool _listening = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  // ================= START REALTIME LISTENER =================
  void startListening() {
    if (_listening) return;
    _listening = true;

    _attachStream();
  }

  void _attachStream() {
    _subscription?.cancel();

    _subscription = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .listen((snapshot) {
      _notifications
        ..clear()
        ..addAll(
          snapshot.docs
              .where((e) => e['createdAt'] != null)
              .map((e) => AppNotification.fromFirestore(e)),
        );

      notifyListeners();
    }, onError: (e) {
      debugPrint('❌ Notification stream error: $e');
    });
  }

  // ================= LOAD MORE =================
  void loadMore() {
    _limit += 10;
    _attachStream(); // 🔁 reattach stream with higher limit
  }

  // ================= STOP LISTENER =================
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
  }

  // ================= MARK AS READ =================
  Future<void> markAsRead(String notificationId, String userId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({
      'readBy.$userId': true,
    });
  }

  // ================= MARK ALL AS READ =================
  Future<void> markAllAsRead(String userId) async {
    if (_notifications.isEmpty) return;

    final batch = _firestore.batch();

    for (final n in _notifications) {
      batch.update(
        _firestore.collection('notifications').doc(n.id),
        {'readBy.$userId': true},
      );
    }

    await batch.commit();
  }



// ================= CREATE =================
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
      'readBy': {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}



