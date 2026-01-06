import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/offline_inventory_provider.dart';
import '../../../providers/offline_transaction_provider.dart';

class UploadToOnlineDialog extends StatefulWidget {
  const UploadToOnlineDialog({super.key});

  @override
  State<UploadToOnlineDialog> createState() => _UploadToOnlineDialogState();
}

class _UploadToOnlineDialogState extends State<UploadToOnlineDialog> {
  bool _loading = false;

  Future<void> _upload() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      // ================= OFFLINE USER CHECK =================
      final box = GetStorage('current_user');
      final rawUser = box.read('current_user');

      if (rawUser == null || rawUser is! Map) {
        throw Exception('No offline user found. Please login online first.');
      }

      final user = Map<String, dynamic>.from(rawUser);
      final String userId = user['id'];

      // ================= READ PROVIDERS =================
      final inventoryProvider = context.read<OfflineInventoryProvider>();
      final transactionProvider = OfflineTransactionsProvider.instance;

      final inventory = inventoryProvider.items.map((e) => e.toJson()).toList();
      final transactions =
      transactionProvider.transactions.map((e) => e.toJson()).toList();

      if (inventory.isEmpty && transactions.isEmpty) {
        throw Exception('No offline data to upload.');
      }

      // ================= FIRESTORE =================
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);

      await FirebaseFirestore.instance
          .collection('syncRequests')
          .doc(dateKey)
          .set({
        'requestId': dateKey,
        'userId': userId,
        'userName': user['fullName'],
        'userEmail': user['email'],
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'inventory': inventory,
        'transactions': transactions,
      });

      // ================= CLEAR OFFLINE DATA =================
      inventoryProvider.clear();
      transactionProvider.clear();

      // Optional: block further edits until approved
      box.write('sync_pending', true);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Offline data uploaded successfully. Awaiting admin approval.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Offline Data'),
      content: const Text(
        'This will upload your offline inventory and transactions '
            'for admin review. Do you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _upload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _loading
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Confirm Upload'),
        ),
      ],
    );
  }
}
