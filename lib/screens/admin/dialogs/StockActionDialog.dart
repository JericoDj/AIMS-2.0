import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/inventoryController.dart';
import '../../../models/ItemModel.dart';
import '../../../providers/accounts_provider.dart';
import '../../../providers/items_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/MyColors.dart';
import '../../../utils/enums/stock_actions_enum.dart';
import 'ConfirmationDialog.dart';

class StockActionDialog extends StatefulWidget {
  final StockActionMode mode;

  const StockActionDialog({super.key, required this.mode});

  @override
  State<StockActionDialog> createState() => _StockActionDialogState();
}

class _StockActionDialogState extends State<StockActionDialog> {
  bool _canSubmit() {
    if (_selectedItem == null) return false;

    // ADD requires expiry
    if (widget.mode == StockActionMode.add && _selectedExpiry == null) {
      return false;
    }

    // DELETE & VIEW do NOT require quantity
    if (widget.mode == StockActionMode.delete ||
        widget.mode == StockActionMode.view) {
      return true;
    }

    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return false;

    return true;
  }

  final TextEditingController _scanCtrl = TextEditingController();
  final FocusNode _scanFocus = FocusNode();

  final FocusNode _qtyFocus = FocusNode();
  final TextEditingController _qtyCtrl = TextEditingController();

  // ✅ MISSING FIELDS (FIX)
  final TextEditingController _expiryCtrl = TextEditingController();
  final FocusNode _expiryFocus = FocusNode();

  bool _isSubmitting = false;
  DateTime? _selectedExpiry;

  ItemModel? _selectedItem;

  List<ItemModel> _filteredItems = [];
  int _selectedIndex = 0;
  int? _hoveredIndex;

  Future<void> _handleEnter() async {
    if (_isSubmitting) return;

    if (!_canSubmit()) {
      if (_selectedItem == null) {
        FocusScope.of(context).requestFocus(_scanFocus);
        return;
      }

      if (widget.mode == StockActionMode.add && _selectedExpiry == null) {
        FocusScope.of(context).requestFocus(_expiryFocus);
        return;
      }

      // ❌ DO NOT ask for qty in DELETE / VIEW
      if (widget.mode != StockActionMode.delete &&
          widget.mode != StockActionMode.view &&
          _qtyCtrl.text.isEmpty) {
        FocusScope.of(context).requestFocus(_qtyFocus);
        return;
      }

      return;
    }

    await _confirmItem(_selectedItem!);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<InventoryProvider>();

      if (provider.items.isEmpty && !provider.loading) {
        await provider.fetchItems(refresh: true);
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
      case StockActionMode.delete:
        return "Delete Stock";
      default:
        throw UnimplementedError();
    }
  }

  // ================= SCAN / SEARCH =================
  List<ItemModel> _handleScanOrSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return [];

    final items = context.read<InventoryProvider>().items;

    final matches =
        items.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

    setState(() {
      _filteredItems = matches;
      _selectedIndex = 0;
      _selectedItem = matches.isNotEmpty ? matches[0] : null;
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

      // 🎨 CUSTOM THEME
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen, // header + selected date
              onPrimary: Colors.white, // header text
              surface: Colors.white, // calendar bg
              onSurface: AppColors.primaryGreen, // calendar text
            ),
            dialogBackgroundColor: Colors.white,

            // 🎯 DAY CELL STYLE
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen, // OK / CANCEL
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // OPTIONAL: Date numbers style
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontWeight: FontWeight.w600),
              bodyMedium: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          child: child!,
        );
      },
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
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final inventory = InventoryController();
    final notifProvider = context.read<NotificationProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final user = context.read<AccountsProvider>().currentUser;

    try {
      // ================= VIEW =================
      if (widget.mode == StockActionMode.view) {
        _showItemDetails(item);
        return;
      }

      // ================= DELETE (FULL ITEM) =================
      if (widget.mode == StockActionMode.delete) {
        // 🗑️ SIMPLE CONFIRMATION DIALOG
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (_) => const ConfirmationDialog(
                title: "Delete Item?",
                message:
                    "This action cannot be undone. Are you sure you want to delete this item?",
                confirmLabel: "Delete Forever",
                confirmColor: Colors.red,
              ),
        );

        if (confirmed != true) {
          if (mounted) setState(() => _isSubmitting = false);
          return;
        }

        await inventory.deleteItem(
          itemId: item.id,
          itemName: item.name,

          user: user,
        );

        await inventoryProvider.fetchItems(refresh: true);

        if (mounted) Navigator.pop(context);
        return;
      }

      final qty = int.tryParse(_qtyCtrl.text);
      if (qty == null || qty <= 0) {
        throw Exception('Invalid quantity');
      }

      // ================= ADD =================
      if (widget.mode == StockActionMode.add) {
        if (_selectedExpiry == null) {
          throw Exception('Expiry date required');
        }

        await inventory.addStock(
          itemId: item.id,
          quantity: qty,
          expiry: _selectedExpiry!,
          user: user,
        );

        await notifProvider.createNotification(
          itemId: item.id,
          itemName: item.name,
          type: 'STOCK_ADDED',
          message: 'Added $qty pcs to ${item.name}',
        );
      }

      // ================= DISPENSE =================
      if (widget.mode == StockActionMode.dispense) {
        await inventory.dispenseStock(
          itemId: item.id,
          quantity: qty,
          user: user,
        );

        await notifProvider.createNotification(
          itemId: item.id,
          itemName: item.name,
          type: 'DISPENSE',
          message: 'Dispensed $qty pcs from ${item.name}',
        );

        await inventoryProvider.checkAndSendStockNotifications(notifProvider);
      }

      await inventoryProvider.fetchItems(refresh: true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ StockAction failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Action failed')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showItemDetails(ItemModel item) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(item.name),
            content: Text("Total Stock: ${item.totalStock}"),
          ),
    );
  }

  void _onScanTextChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _filteredItems.clear();
      });
      return;
    }

    _handleScanOrSearch(value);
  }

  void _selectItem(ItemModel item) {
    _selectedItem = item;

    // DELETE & VIEW → confirm immediately
    if (widget.mode == StockActionMode.delete ||
        widget.mode == StockActionMode.view) {
      _confirmItem(item);
      return;
    }

    // ADD / DISPENSE → focus qty
    if (_qtyCtrl.text.isEmpty) {
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
    _expiryCtrl.dispose();
    _scanFocus.dispose();
    _qtyFocus.dispose();
    _expiryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.primaryGreen, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.primaryGreen),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= SCAN =================
            _styledField(
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    final value = _scanCtrl.text.trim();
                    if (value.isEmpty) return;

                    final matches = _handleScanOrSearch(value);
                    if (matches.isNotEmpty) {
                      _selectItem(matches[_selectedIndex]);
                    }
                    // _scanCtrl.clear();
                  }
                },
                child: Align(
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _scanCtrl,
                    focusNode: _scanFocus,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _onScanTextChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Scan QR or search item",
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ),
              ),
            ),

            // ================= EXPIRY =================
            if (widget.mode == StockActionMode.add) ...[
              const SizedBox(height: 12),
              _styledField(
                child: TextField(
                  controller: _expiryCtrl,
                  focusNode: _expiryFocus,
                  textAlignVertical: TextAlignVertical.center,
                  readOnly: true,
                  onTap: _pickExpiry,
                  onSubmitted: (_) async => await _handleEnter(),

                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Expiry Date",
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ],

            // ================= QTY =================
            if (widget.mode != StockActionMode.view &&
                widget.mode != StockActionMode.delete) ...[
              const SizedBox(height: 12),
              _styledField(
                child: TextField(
                  controller: _qtyCtrl,
                  focusNode: _qtyFocus,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) async => await _handleEnter(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Quantity",
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ================= ITEM LIST =================
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  _filteredItems.isEmpty
                      ? const Center(
                        child: Text(
                          "No items found",
                          style: TextStyle(color: Colors.black87),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (_, index) {
                          final item = _filteredItems[index];
                          final selected = _selectedItem?.id == item.id;

                          return InkWell(
                            onTap: () => _selectItem(item),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      selected
                                          ? AppColors.primaryGreen
                                          : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "${item.totalStock} pcs",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      // 🗑️ DELETE ICON (View Mode + Admin Only)
                                      if (widget.mode == StockActionMode.view &&
                                          context
                                              .read<AccountsProvider>()
                                              .isAdmin) ...[
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            // 🗑️ SIMPLE CONFIRMATION DIALOG
                                            final confirmed = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (_) => ConfirmationDialog(
                                                    title:
                                                        "Delete ${item.name}?",
                                                    message:
                                                        "This action cannot be undone. Are you sure you want to delete this item?",
                                                    confirmLabel: "Delete",
                                                    confirmColor: Colors.red,
                                                  ),
                                            );

                                            if (confirmed == true) {
                                              if (!mounted) return;
                                              // Call delete logic manually since we are bypassing _selectItem -> _confirmItem flow for this button
                                              // Actually better to reuse _confirmItem logic but force mode to delete?
                                              // Or just implement it here cleanly.

                                              // Let's use the controller directly here to keep it simple as this is a specific action button
                                              setState(
                                                () => _isSubmitting = true,
                                              );
                                              try {
                                                final user =
                                                    context
                                                        .read<
                                                          AccountsProvider
                                                        >()
                                                        .currentUser;
                                                await InventoryController()
                                                    .deleteItem(
                                                      itemId: item.id,
                                                      itemName: item.name,
                                                      user: user,
                                                    );
                                                await context
                                                    .read<InventoryProvider>()
                                                    .fetchItems(refresh: true);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Item deleted successfully',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                debugPrint("Delete error: $e");
                                              } finally {
                                                if (mounted)
                                                  setState(
                                                    () => _isSubmitting = false,
                                                  );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                "Scan barcode or type item name then press Enter",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledField({required Widget child}) {
    return Container(
      height: 52, // ✅ fixed height (critical)
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center, // ✅ centers child
      child: child,
    );
  }
}
