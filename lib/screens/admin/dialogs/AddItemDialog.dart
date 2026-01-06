import 'package:aims2frontend/screens/admin/dialogs/dialog_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/inventoryController.dart';
import '../../../providers/accounts_provider.dart';
import '../../../providers/items_provider.dart';
import '../../../utils/enums/item_enum.dart';

class AddItemDialog extends StatefulWidget {
  final BuildContext parentContext;
  const AddItemDialog({
    required this.parentContext,
    super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

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
    final accounts = context.read<AccountsProvider>();
    final user = accounts.currentUser;

    final name = _nameCtrl.text.trim();
    print(name);
    print("heres the name");
    final quantity = int.tryParse(_qtyCtrl.text);

    print(quantity);
    print("heres the quantity");

    if (name.isEmpty ||
        _category == null ||
        quantity == null ||
        quantity <= 0 ||
        _expiryDate == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return false;
    }

    setState(() => _loading = true);

    try {

      print("setting the inventory");
      final inventory = InventoryController();
      print("inventory set done");

      print("checking item name");
      final exists = await inventory.itemNameExists(name);



      if (exists) {
        print("item already exists");
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Item already exists'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      print("creating item");
      final itemId = await inventory.createItem(
        name: name,
        category: _category!.name,
        user: user,
      );



      print("item created");

      print("item adding stock");
      await inventory.addStock(
        itemId: itemId,
        quantity: quantity,
        expiry: _expiryDate!,
        user: user,
      );

      print("stock added");
      print("updating list");
      context.read<InventoryProvider>().fetchItems(refresh: true);
      print('list updated');
      return true;
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
              Text(
                "Add New Item",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),

              const SizedBox(height: 20),

              DialogTextField(
                label: "Item Name",
                controller: _nameCtrl,
              ),

              const SizedBox(height: 12),

              /// CATEGORY (ENUM)
              DropdownButtonFormField<ItemCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ItemCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.label),
                  );
                }).toList(),
                onChanged: _loading ? null : (val) {
                  setState(() => _category = val);
                },
              ),

              const SizedBox(height: 12),

              /// QUANTITY (INT ONLY)
              DialogTextField(
                label: "Quantity",
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,

              ),

              const SizedBox(height: 12),

              /// EXPIRY DATE PICKER
              InkWell(
                onTap: _loading
                    ? null
                    : () async {
                  final picked = await showDatePicker(
                    context: context,
                    useRootNavigator: false,
                    firstDate: DateTime.now(),
                    lastDate:
                    DateTime.now().add(const Duration(days: 365 * 10)),
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
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red),
                    ),

                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: const Text(
                          style: TextStyle(
                              color: Colors.red),
                          "Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                      final success = await _save();
                      if (success && mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    child: _loading
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child:
                      CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                        style: TextStyle(fontWeight: FontWeight.bold,
                            color: Colors.white),
                        "Save"),
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
