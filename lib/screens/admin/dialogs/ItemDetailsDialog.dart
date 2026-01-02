import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/ItemModel.dart';
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
    _lowStockCtrl = TextEditingController(
      text: (widget.item.lowStockThreshold ?? 10).toString(),
    );
  }

  @override
  void dispose() {
    _lowStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();

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
                  )
                ],
              ),

              const SizedBox(height: 10),
              Text("Category: ${widget.item.category}"),
              const Divider(),

              // ================= STOCK SUMMARY =================
              Text(
                "Total Stock: ${widget.item.totalStock}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // ================= LOW STOCK EDIT =================
              Row(
                children: [
                  const Text("Low Stock Threshold"),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
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
                      if (value == null) return;

                      await provider.updateLowStockThreshold(
                        itemId: widget.item.id,
                        value: value,
                      );

                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= BATCHES =================
              const Text(
                "Batches",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: widget.item.batches.length,
                  itemBuilder: (_, index) {
                    final batch = widget.item.batches[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.inventory_2),
                      title: Text(
                        "Qty: ${batch.quantity}",
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
