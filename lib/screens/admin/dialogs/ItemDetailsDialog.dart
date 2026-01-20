import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/ItemModel.dart';
import '../../../providers/accounts_provider.dart';
import '../../../providers/items_provider.dart';

class ItemDetailsDialog extends StatefulWidget {
  final ItemModel item;

  const ItemDetailsDialog({super.key, required this.item});

  @override
  State<ItemDetailsDialog> createState() => _ItemDetailsDialogState();
}

class _ItemDetailsDialogState extends State<ItemDetailsDialog> {
  late TextEditingController _lowStockCtrl;

  @override
  void initState() {
    super.initState();
    _lowStockCtrl =
        TextEditingController(text: widget.item.lowStockThreshold.toString());
  }

  @override
  void dispose() {
    _lowStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    String _formatCategory(String raw) {
      final v = raw.toLowerCase();

      if (v.contains("dsb")) return "DSB";
      if (v.contains("bmc")) return "BMC";
      if (v.contains("pgb")) return "PGB";

      return raw.toUpperCase();
    }
    final inventoryProvider = context.read<InventoryProvider>();
    final isAdmin = context.watch<AccountsProvider>().isAdmin;

    return Dialog(
      insetPadding: const EdgeInsets.all(30),
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text("Category: ${_formatCategory(widget.item.category)}"),
              const Divider(),

              // ================= STOCK SUMMARY =================
              Text(
                "Total Stock: ${widget.item.totalStock}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              if (widget.item.hasExcess)
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Excess Usage: ${widget.item.excessUsage}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  "Excess Usage: 0",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),

              const SizedBox(height: 14),

              // ================= LOW STOCK EDIT =================
              if (isAdmin)
                Row(
                  children: [
                    const Text("Low Stock Threshold"),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _lowStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        final value =
                        int.tryParse(_lowStockCtrl.text.trim());
                        if (value == null || value < 1) return;

                        await inventoryProvider.updateLowStockThreshold(
                          itemId: widget.item.id,
                          value: value,
                        );
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // ================= BATCHES =================
              const Text(
                "Batches",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: widget.item.batches.length,
                  itemBuilder: (_, index) {
                    final batch = widget.item.batches[index];

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.inventory_2),
                      title: Row(
                        children: [
                          const Text("Qty: "),
                          const SizedBox(width: 6),
                          isAdmin
                              ? _EditableBatchQty(
                            itemId: widget.item.id,
                            batchIndex: index,
                            initialQty: batch.quantity,
                          )
                              : Text(
                            batch.quantity.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        "Expiry: ${batch.expiryFormatted}",
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// =================== EDITABLE BATCH QTY =========================
// ================================================================
class _EditableBatchQty extends StatefulWidget {
  final String itemId;
  final int batchIndex;
  final int initialQty;

  const _EditableBatchQty({
    required this.itemId,
    required this.batchIndex,
    required this.initialQty,
  });

  @override
  State<_EditableBatchQty> createState() => _EditableBatchQtyState();
}

class _EditableBatchQtyState extends State<_EditableBatchQty> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQty.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.save, color: Colors.green),
          onPressed: _saving
              ? null
              : () async {
            final value = int.tryParse(_ctrl.text.trim());
            if (value == null || value < 0) return;

            setState(() => _saving = true);

            await provider.updateBatchQuantity(
              itemId: widget.itemId,
              batchIndex: widget.batchIndex,
              newQty: value,
            );

            if (!mounted) return;

            Navigator.pop(context); // ✅ CLOSE DIALOG
          },
        ),
      ],
    );
  }
}

