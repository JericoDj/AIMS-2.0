import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/AppNotification.dart';
class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<AppNotification> _notifications = [];

  bool _loading = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _pageSize = 5;

  // ---------------- GETTERS ----------------
  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  // ---------------- INITIAL FETCH ----------------
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_loading) return;

    if (refresh) {
      _notifications.clear();
      _lastDoc = null;
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore) return;

    _loading = true;
    notifyListeners();

    Query query = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _notifications.addAll(
        snap.docs.map((e) => AppNotification.fromFirestore(e)),
      );
    }

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

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] =
          _notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }
}
