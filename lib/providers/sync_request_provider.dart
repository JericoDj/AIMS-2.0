// providers/sync_request_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/syncRequestController.dart';
import '../models/SyncRequestModel.dart';
import 'accounts_provider.dart';

class SyncRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncRequestController _controller;

  SyncRequestProvider(AccountsProvider accountsProvider)
    : _controller = SyncRequestController(accountsProvider) {
    if (accountsProvider.isAdmin) {
      startListening();
    }
  }

  bool loading = false;
  bool syncing = false;

  final List<SyncRequest> _requests = [];
  List<SyncRequest> get requests => List.unmodifiable(_requests);

  // ================= LOAD PENDING =================
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  // ================= START LISTENING (STREAM) =================
  void startListening() {
    if (_subscription != null) return; // Already listening

    loading = true;
    notifyListeners();

    try {
      _subscription = _firestore
          .collection('syncRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _requests.clear();
              for (final doc in snapshot.docs) {
                _requests.add(SyncRequest.fromFirestore(doc.id, doc.data()));
              }
              loading = false;
              notifyListeners();
            },
            onError: (e) {
              debugPrint('❌ SyncRequest stream error: $e');
              loading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('❌ startListening failed: $e');
      loading = false;
      notifyListeners();
    }
  }

  // ================= STOP LISTENING =================
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ================= APPROVE =================
  // ================= APPROVE =================
  Future<void> approve(SyncRequest request) async {
    debugPrint('✅ Approve called for request id: ${request.id}');
    if (syncing) return;

    syncing = true;
    notifyListeners();

    try {
      await _controller.applySync(request);

      // ✅ REMOVE FROM LOCAL LIST AFTER SUCCESS
      _requests.removeWhere((r) => r.id == request.id);
    } catch (e, s) {
      debugPrint('❌ approve failed: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  // ================= REJECT =================
  Future<void> reject(SyncRequest request) async {
    if (syncing) return;

    syncing = true;
    notifyListeners();

    try {
      await _controller.rejectSync(request);

      // 🔥 delete locally after Firestore delete
      _requests.removeWhere((r) => r.id == request.id);
    } catch (e) {
      debugPrint('❌ reject failed: $e');
      rethrow;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
