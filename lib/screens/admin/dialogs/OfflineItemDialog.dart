import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/offlineInventoryController.dart';
import '../../../providers/offline_inventory_provider.dart';
import '../../../utils/enums/item_enum.dart';
import 'dialog_text_field.dart';

class OfflineAddItemDialog extends StatefulWidget {
  const OfflineAddItemDialog({super.key});

  @override
  State<OfflineAddItemDialog> createState() => _OfflineAddItemDialogState();
}

class _OfflineAddItemDialogState extends State<OfflineAddItemDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: "0");

  ItemCategory? _category;
  DateTime? _expiryDate;

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (_loading) return false;

    final messenger = ScaffoldMessenger.maybeOf(context);

    final name = _nameCtrl.text.trim().toUpperCase();
    final quantity = int.tryParse(_qtyCtrl.text);

    if (name.isEmpty ||
        _category == null ||
        quantity == null ||
        quantity <= -1 ||
        _expiryDate == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return false;
    }

    setState(() => _loading = true);

    try {
      final inventory = OfflineInventoryController();

      // 🔍 CHECK NAME (ASYNC)
      final exists = await inventory.itemNameExists(name);
      if (exists) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Item already exists (offline)'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // 🧱 CREATE ITEM (NO STOCK YET)
      final itemId = await inventory.createItem(
        name: name,
        category: _category!.name,
      );

      // 📦 ADD INITIAL STOCK
      await inventory.addStock(
        itemId: itemId,
        quantity: quantity,
        expiry: _expiryDate!,
      );

      // 🔄 REFRESH PROVIDER FROM CONTROLLER STATE
      await context.read<OfflineInventoryProvider>().reload();

      return true;
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add New Item (Offline)",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 20),

              DialogTextField(
                label: "Item Name",
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.characters,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<ItemCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items:
                    ItemCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.label),
                      );
                    }).toList(),
                onChanged:
                    _loading
                        ? null
                        : (val) {
                          setState(() => _category = val);
                        },
              ),

              const SizedBox(height: 12),

              DialogTextField(
                label: "Quantity",
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap:
                    _loading
                        ? null
                        : () async {
                          final picked = await showDatePicker(
                            context: context,
                            useRootNavigator: false,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 10),
                            ),
                            initialDate: DateTime.now(),
                          );

                          if (picked != null && mounted) {
                            setState(() => _expiryDate = picked);
                          }
                        },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _expiryDate == null
                        ? 'Select date'
                        : _expiryDate!.toIso8601String().split('T').first,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        _loading
                            ? null
                            : () async {
                              final success = await _save();
                              if (success && mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                    child:
                        _loading
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text("Save"),
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
