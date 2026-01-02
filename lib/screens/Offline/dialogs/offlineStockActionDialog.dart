import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/offlineInventoryController.dart';
import '../../../models/ItemModel.dart';
import '../../../providers/offline_inventory_provider.dart';
import '../../../utils/enums/stock_actions_enum.dart';

class OfflineStockActionDialog extends StatefulWidget {
  final StockActionMode mode;

  const OfflineStockActionDialog({
    super.key,
    required this.mode,
  });

  @override
  State<OfflineStockActionDialog> createState() =>
      _OfflineStockActionDialogState();
}

class _OfflineStockActionDialogState
    extends State<OfflineStockActionDialog> {
  final TextEditingController _scanCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();


  final TextEditingController _expiryCtrl = TextEditingController();
  final FocusNode _expiryFocus = FocusNode();
  DateTime? _selectedExpiry;

  final FocusNode _scanFocus = FocusNode();
  final FocusNode _qtyFocus = FocusNode();

  ItemModel? _selectedItem;

  List<ItemModel> _filteredItems = [];
  int _selectedIndex = 0;
  int? _hoveredIndex;

  final OfflineInventoryController _inventory =
  OfflineInventoryController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<OfflineInventoryProvider>();

      if (provider.items.isEmpty && !provider.loading) {
        await provider.loadItems();
      }

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

  // ================= SEARCH / SCAN =================
  List<ItemModel> _handleScanOrSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return [];

    final items =
        context.read<OfflineInventoryProvider>().items;

    final matches = items.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredItems = matches;
      _selectedIndex = 0;
    });

    return matches;
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiry = picked;
        _expiryCtrl.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  // ================= CONFIRM =================
  Future<void> _confirmItem(ItemModel item) async {
    if (widget.mode == StockActionMode.view) {
      _showItemDetails(item);
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;

    if (widget.mode == StockActionMode.add) {
      if (_selectedExpiry == null) return;

      await _inventory.addStock(
        itemId: item.id,
        quantity: qty,
        expiry: _selectedExpiry!,
      );
    }

    if (widget.mode == StockActionMode.dispense) {
      await _inventory.dispenseStock(
        itemId: item.id,
        quantity: qty,
      );
    }

    context.read<OfflineInventoryProvider>().reload();
    Navigator.of(context).pop();
  }

  void _selectItem(ItemModel item) {
    _selectedItem = item;

    if (widget.mode != StockActionMode.view &&
        _qtyCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_qtyFocus);
      });
    } else {
      _confirmItem(item);
    }
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
    _qtyFocus.dispose();
    _expiryCtrl.dispose();
    _expiryFocus.dispose();
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
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ================= SCAN INPUT =================
            // ================= SCAN INPUT =================
            RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                  final value = _scanCtrl.text.trim();
                  if (value.isEmpty) return;

                  final matches = _handleScanOrSearch(value);

                  if (matches.length == 1) {
                    _selectItem(matches.first);
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


            // ================= EXPIRY =================
            if (widget.mode == StockActionMode.add) ...[
              const SizedBox(height: 12),

              RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    if (_selectedExpiry == null) {
                      _pickExpiry(); // open date picker
                    } else {
                      FocusScope.of(context).requestFocus(_qtyFocus);
                    }
                  }
                },
                child: TextField(
                  controller: _expiryCtrl,
                  focusNode: _expiryFocus,
                  readOnly: true,
                  onTap: _pickExpiry,
                  decoration: const InputDecoration(
                    labelText: "Expiry Date",
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ],


            const SizedBox(height: 12),

            // ================= QTY =================
            if (widget.mode != StockActionMode.view)
              RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey ==
                          LogicalKeyboardKey.enter ||
                          event.logicalKey ==
                              LogicalKeyboardKey.numpadEnter)) {
                    if (_selectedItem == null) return;

                    _confirmItem(_selectedItem!);
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
                  : MouseRegion(
                onExit: (_) {
                  setState(() => _hoveredIndex = null);
                },
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (_, index) {
                    final item = _filteredItems[index];

                    final isHovered =
                        _hoveredIndex == index;
                    final isSelected =
                        _hoveredIndex == null &&
                            index == _selectedIndex;

                    return MouseRegion(
                      onEnter: (_) {
                        setState(
                                () => _hoveredIndex = index);
                      },
                      child: Container(
                        color: isHovered
                            ? Colors.green
                            .withOpacity(0.25)
                            : isSelected
                            ? Colors.green
                            .withOpacity(0.15)
                            : null,
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                              "Stock: ${item.totalStock}"),
                          onTap: () => _selectItem(item),
                        ),
                      ),
                    );
                  },
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
