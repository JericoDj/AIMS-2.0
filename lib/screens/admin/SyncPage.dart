import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/SyncRequestModel.dart';
import '../../providers/sync_request_provider.dart';
import 'dialogs/SyncRequestDialog.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncRequestProvider>().startListening();
    });
  }

  @override
  void dispose() {
    // context.read would be unsafe here if the widget is unmounted contextually,
    // but usually provider is fine. However, robust way is to just let provider handle it
    // or call stop if we want to save resources when leaving this page.
    // Since SyncRequestProvider might be global, maybe we don't stop listening?
    // BUT the plan said "Handle subscription cancellation in dispose()".
    // If the provider is scoped to the app, stopping it here might stop it for everyone (e.g. the badge).
    // WAIT. If we want the badge to verify requests count GLOBALLY, the provider should PROBABLY listen ALL THE TIME
    // or at least when the Admin is logged in.
    // If I stop listening here, the badge in StockMonitoringPage will stop updating!
    // Result: I should NOT stop listening here if I want the badge to work elsewhere.
    // I will just start listening here (idempotent check in provider).
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncRequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sync Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Removed Refresh button as it is real-time now
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(SyncRequestProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No pending sync requests',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: provider.requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final req = provider.requests[index];
        return _SyncRequestCard(request: req, provider: provider);
      },
    );
  }
}

//
// ========================= REQUEST CARD =========================
//
class _SyncRequestCard extends StatelessWidget {
  final SyncRequest request;
  final SyncRequestProvider provider;

  const _SyncRequestCard({required this.request, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => SyncRequestDetailsDialog(request: request),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(),
                ],
              ),

              const SizedBox(height: 12),

              // ================= DETAILS =================
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.inventory_2,
                    label: '${request.inventory.length} items',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.swap_horiz,
                    label: '${request.transactions.length} transactions',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ================= ACTIONS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Reject'),
                    onPressed:
                        provider.syncing
                            ? null
                            : () async {
                              await provider.reject(request);
                            },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        provider.syncing
                            ? null
                            : () async {
                              await provider.approve(request);
                            },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// ========================= STATUS CHIP =========================
//
class _StatusChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange),
      ),
      child: const Text(
        'PENDING',
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

//
// ========================= INFO CHIP =========================
//
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.green),
      label: Text(label),
      backgroundColor: Colors.green.withOpacity(0.1),
    );
  }
}
