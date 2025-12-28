import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sync_provider.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Sync Requests")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (sync.pendingTransactions.isEmpty)
              const Center(child: Text("No pending sync requests"))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: sync.pendingTransactions.length,
                  itemBuilder: (_, index) {
                    final tx = sync.pendingTransactions[index];

                    return ListTile(
                      leading: const Icon(Icons.sync_problem),
                      title: Text(tx.itemName ?? 'Unknown Item'),
                      subtitle: Text(
                        "${tx.type.name} • ${tx.quantity ?? '-'}",
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: sync.syncing
                  ? null
                  : () async {
                await sync.performSync();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Sync Now"),
            ),
          ],
        ),
      ),
    );
  }
}
