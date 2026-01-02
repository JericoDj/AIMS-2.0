// providers/sync_request_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/syncRequestController.dart';
import '../models/SyncRequestModel.dart';

class SyncRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncRequestController _controller = SyncRequestController();

  bool loading = false;
  bool syncing = false;

  final List<SyncRequest> _requests = [];
  List<SyncRequest> get requests => List.unmodifiable(_requests);

  // ================= LOAD PENDING =================
  Future<void> loadPendingRequests() async {
    if (loading) return;

    loading = true;
    notifyListeners();

    try {
      _requests.clear();

      final snapshot = await _firestore
          .collection('syncRequests') // ✅ FLAT COLLECTION
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        _requests.add(
          SyncRequest.fromFirestore(
            doc.id,
            doc.data(),
          ),
        );
      }
    } catch (e, s) {
      debugPrint('❌ loadPendingRequests failed: $e');
      debugPrintStack(stackTrace: s);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ================= APPROVE =================
  Future<void> approve(SyncRequest request) async {
    if (syncing) return;

    syncing = true;
    notifyListeners();

    try {
      await _controller.applySync(request);

      _requests.removeWhere((r) => r.id == request.id);
    } catch (e) {
      debugPrint('❌ approve failed: $e');
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
