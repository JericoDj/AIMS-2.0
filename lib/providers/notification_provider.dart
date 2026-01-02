import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/AppNotification.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<AppNotification> _notifications = [];
  bool _loading = false;

  // ---------------- GETTERS ----------------
  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;

  // ---------------- FETCH ----------------
  Future<void> fetchNotifications() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    final snap = await _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    _notifications
      ..clear()
      ..addAll(
        snap.docs.map((e) => AppNotification.fromFirestore(e)),
      );

    _loading = false;
    notifyListeners();
  }

  // ---------------- CREATE ----------------
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

  // ---------------- MARK AS READ ----------------
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});

    final index =
    _notifications.indexWhere((n) => n.id == notificationId);

    if (index != -1) {
      _notifications[index] =
          _notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }
}
