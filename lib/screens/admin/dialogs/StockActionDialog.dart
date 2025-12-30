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

    final FocusNode _qtyFocus = FocusNode();
    ItemModel? _selectedItem;

    final TextEditingController _qtyCtrl = TextEditingController();

    List<ItemModel> _filteredItems = [];
    int _selectedIndex = 0;

    int? _hoveredIndex;

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
    List<ItemModel> _handleScanOrSearch(String value) {
      final query = value.trim();
      if (query.isEmpty) return [];

      final items = context.read<InventoryProvider>().items;

      final matches = items.where((item) {
        return item.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        _filteredItems = matches;
        _selectedIndex = 0;
      });

      return matches;
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
    void _selectItem(ItemModel item) {
      _selectedItem = item;

      if (widget.mode != StockActionMode.view &&
          _qtyCtrl.text.isEmpty) {
        // move to qty if not yet set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_qtyFocus);
        });
      } else {
        _confirmItem(item);
      }
    }

    @override
    void dispose() {
      _scanCtrl.dispose();
      _qtyCtrl.dispose();
      _scanFocus.dispose();
      _qtyFocus.dispose();
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
              // ================= SCAN INPUT =================
              RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {

                    final value = _scanCtrl.text.trim();
                    if (value.isEmpty) return;

                    final matches = _handleScanOrSearch(value);

                    if (matches.length == 1) {
                      _selectItem(matches.first);

                      if (widget.mode != StockActionMode.view &&
                          _qtyCtrl.text.isEmpty) {

                        // ⏱ ensure focus AFTER rebuild
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).requestFocus(_qtyFocus);
                        });

                      } else {
                        _confirmItem(_selectedItem!);
                      }
                    }

                    _scanCtrl.clear();
                  }
                },
                child: TextField(
                  controller: _scanCtrl,
                  focusNode: _scanFocus,
                  autofocus: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: "Scan QR or search item",
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
                ),
              ),




              const SizedBox(height: 12),

              // ================= QTY =================
              if (widget.mode != StockActionMode.view)
                RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (RawKeyEvent event) {
                    if (event is RawKeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {

                      if (_selectedItem == null) return;

                      final qty = int.tryParse(_qtyCtrl.text);
                      if (qty == null || qty <= 0) return;

                      _confirmItem(_selectedItem!);

                      // reset for next scan
                      _qtyCtrl.clear();
                      _selectedItem = null;
                      FocusScope.of(context).requestFocus(_scanFocus);
                    }
                  },
                  child: TextField(
                    controller: _qtyCtrl,
                    focusNode: _qtyFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                    ),
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
                    : SizedBox(
                  height: 200,
                  child: _filteredItems.isEmpty
                      ? const Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : MouseRegion(
                    onExit: (_) {
                      setState(() {
                        _hoveredIndex = null; // restore top selection
                      });
                    },
                    child: ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (_, index) {
                        final item = _filteredItems[index];

                        final isHovered = _hoveredIndex == index;
                        final isSelected =
                            _hoveredIndex == null && index == _selectedIndex;

                        return MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredIndex = index;
                            });
                          },
                          child: Container(
                            color: isHovered
                                ? Colors.green.withOpacity(0.25)
                                : isSelected
                                ? Colors.green.withOpacity(0.15)
                                : null,
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text("Stock: ${item.totalStock}"),
                              onTap: () => _selectItem(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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


