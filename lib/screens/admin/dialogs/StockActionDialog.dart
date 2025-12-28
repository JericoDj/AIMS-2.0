  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:provider/provider.dart';

  import '../../../controllers/inventoryController.dart';
  import '../../../models/ItemModel.dart';
  import '../../../providers/items_provider.dart';
  import '../../../utils/enums/stock_actions_enum.dart';

  class StockActionDialog extends StatefulWidget {
    final StockActionMode mode;

    const StockActionDialog({super.key, required this.mode});

    @override
    State<StockActionDialog> createState() => _StockActionDialogState();
  }

  class _StockActionDialogState extends State<StockActionDialog> {
    final TextEditingController _scanCtrl = TextEditingController();
    final FocusNode _scanFocus = FocusNode();

    final TextEditingController _qtyCtrl = TextEditingController();

    List<ItemModel> _filteredItems = [];
    int _selectedIndex = 0;

    @override
    void initState() {
      super.initState();

      // 🔑 Force focus AFTER dialog is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_scanFocus);
        }
      });
    }

    String get _title {
      switch (widget.mode) {
        case StockActionMode.view:
          return "View Stock";
        case StockActionMode.add:
          return "Add Stock";
        case StockActionMode.dispense:
          return "Dispense Stock";
      }
    }

    // ================= SCAN / SEARCH =================
    void _handleScanOrSearch(String value) {
      print("working");
      print(value);
      final query = value.trim();
      if (query.isEmpty) return;

      final items = context.read<InventoryProvider>().items;
      print("printing the items");
      print(items);

      final matches = items.where((item) {
        return item.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        _filteredItems = matches;
        _selectedIndex = 0;
      });
    }

    // ================= CONFIRM =================
    Future<void> _confirmItem(ItemModel item) async {
      final inventory = InventoryController();

      if (widget.mode == StockActionMode.view) {
        _showItemDetails(item);
        return;
      }

      final qty = int.tryParse(_qtyCtrl.text);
      if (qty == null || qty <= 0) return;

      if (widget.mode == StockActionMode.add) {
        await inventory.addStock(
          itemId: item.id,
          quantity: qty,
          expiry: DateTime.now().add(const Duration(days: 365)),
        );
      }

      if (widget.mode == StockActionMode.dispense) {
        await inventory.dispenseStock(
          itemId: item.id,
          quantity: qty,
        );
      }

      context.read<InventoryProvider>().fetchItems(refresh: true);
      Navigator.pop(context);
    }

    void _showItemDetails(ItemModel item) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(item.name),
          content: Text("Total Stock: ${item.totalStock}"),
        ),
      );
    }

    @override
    void dispose() {
      _scanCtrl.dispose();
      _qtyCtrl.dispose();
      _scanFocus.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================= HEADER WITH CLOSE =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(),

                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ================= SCAN INPUT =================
              TextField(
                controller: _scanCtrl,
                focusNode: _scanFocus,
                autofocus: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: "Scan barcode or search item",
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                onSubmitted: (value) {
                  _handleScanOrSearch(value.trim());
                  _scanCtrl.clear();
                },
              ),

              const SizedBox(height: 12),

              // ================= QTY =================
              if (widget.mode != StockActionMode.view)
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                  ),
                ),

              const SizedBox(height: 16),

              // ================= ITEM LIST =================
              SizedBox(
                height: 200,
                child: _filteredItems.isEmpty
                    ? const Center(
                  child: Text(
                    "No items found",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (_, index) {
                    final item = _filteredItems[index];
                    final selected = index == _selectedIndex;

                    return Container(
                      color: selected
                          ? Colors.green.withOpacity(0.15)
                          : null,
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text("Stock: ${item.totalStock}"),
                        onTap: () => _confirmItem(item),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Scan barcode or type item name then press Enter",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }


  }


