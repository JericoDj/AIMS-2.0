import 'package:flutter/material.dart';
import '../../../models/SyncRequestModel.dart';

class SyncRequestDetailsDialog extends StatelessWidget {
  final SyncRequest request;

  const SyncRequestDetailsDialog({
    super.key,
    required this.request,
  });

  // ================= HELPERS =================
  int _totalFromBatches(List<dynamic>? batches) {
    if (batches == null) return 0;

    return batches.fold<int>(
      0,
          (sum, b) => sum + ((b['quantity'] ?? 0) as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(30),
      child: SizedBox(
        width: 800,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    "Sync Request Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ================= CONTENT =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // ================= INVENTORY =================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Inventory",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: request.inventory.length,
                              itemBuilder: (_, i) {
                                final item = request.inventory[i];
                                final batches =
                                item['batches'] as List<dynamic>?;

                                final totalQty =
                                _totalFromBatches(batches);

                                return Card(
                                  elevation: 1,
                                  margin:
                                  const EdgeInsets.only(bottom: 8),
                                  child: ExpansionTile(
                                    title: Text(
                                      item['name'] ?? 'Unnamed Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Total Qty: $totalQty'
                                          '${batches != null ? " • ${batches.length} batch(es)" : ""}',
                                    ),
                                    children: batches == null
                                        ? []
                                        : batches.map<Widget>((b) {
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          'Qty: ${b['quantity']}',
                                        ),
                                        subtitle: Text(
                                          'Expiry: ${b['expiry']}',
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 24),

                    // ================= TRANSACTIONS =================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Transactions",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: request.transactions.length,
                              itemBuilder: (_, i) {
                                final tx = request.transactions[i];

                                return Card(
                                  elevation: 1,
                                  margin:
                                  const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      tx['itemName'] ?? 'Unknown Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${tx['type'] ?? 'unknown'}'
                                          '${tx['quantity'] != null ? " • Qty: ${tx['quantity']}" : ""}',
                                    ),
                                    trailing: Text(
                                      tx['timestamp'] != null
                                          ? tx['timestamp']
                                          .toString()
                                          .split('.')
                                          .first
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
