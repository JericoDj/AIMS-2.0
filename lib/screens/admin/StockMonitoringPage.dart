import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../controllers/inventoryTransactionReportController.dart';
import '../../models/ItemModel.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/items_provider.dart';
import '../../utils/enums/stock_filter_enum.dart'; // Restored
import 'dialogs/AddItemDialog.dart'; // Restored
import 'dialogs/InventoryDialog.dart'; // Restored
import 'dialogs/ItemDetailsDialog.dart'; // Restored
import 'dialogs/StockActionDialog.dart';
import 'widgets/ReusableButton.dart';
import '../../utils/enums/stock_actions_enum.dart';

class StockMonitoringPage extends StatefulWidget {
  final StockFilter? initialFilter;
  final String? initialSearch;

  const StockMonitoringPage({
    this.initialSearch,
    this.initialFilter,
    super.key,
  });

  @override
  State<StockMonitoringPage> createState() => _StockMonitoringPageState();
}

class _StockMonitoringPageState extends State<StockMonitoringPage> {
  StockFilter _filter = StockFilter.all;
  String _searchQuery = '';

  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();

    _filter = widget.initialFilter ?? StockFilter.all;

    _searchCtrl = TextEditingController(
      text: widget.initialSearch?.toLowerCase() ?? '',
    );

    _searchQuery = _searchCtrl.text;

    Future.microtask(() {
      context.read<InventoryProvider>().fetchItems(refresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant StockMonitoringPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != null) {
      setState(() {
        _filter = widget.initialFilter!;
      });
    }

    if (widget.initialSearch != oldWidget.initialSearch &&
        widget.initialSearch != null) {
      setState(() {
        _searchQuery = widget.initialSearch!.toLowerCase();
        _searchCtrl.text = _searchQuery;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AccountsProvider>().isAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // ---------------- PAGE TITLE ----------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Stock Monitoring${isAdmin ? ' (Admin)' : ''}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),

            Row(
              children: [
                // TestBarcodeToDesktopButton(
                //   input: 'item2', // 🔐 value to encrypt (for crypto test)
                // ),

                // DecodeAssetBarcodeButton(),

                //
                // TestEncryptionDecryptionButton(input: "item2"),
                // TestBarcodeRoundTripButton(
                //   barcodeValue: 'Biogesic',
                // ),

                //
                //
                // DecodeBarcodeButton(assetPath: "assets/barcode.png", originalName: "test3"),
                // Sync indicator removed from here
                if (isAdmin)
                  ReusableButton(
                    label: "Add\nItem",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddItemDialog(parentContext: context),
                      );
                    },
                  ),

                const SizedBox(width: 10),

                if (isAdmin)
                  ReusableButton(
                    label: "Delete\nItem",
                    color: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => const StockActionDialog(
                              mode: StockActionMode.delete,
                            ),
                      );
                    },
                  ),

                const SizedBox(width: 10),

                ReusableButton(
                  label: "Inventory\nReport",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => InventoryReportDialog(
                            onGenerate: (start, end, category) async {
                              await InventoryTransactionReportController.generateInventoryReport(
                                context,
                                start: start,
                                end: end,
                                category: category,
                              );
                            },
                          ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ---------------- SEARCH + FILTERS ----------------
        Row(
          children: [
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _searchCtrl,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search item...",
                      icon: Icon(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        Icons.search,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            _FilterChip(
              label: "All",
              color: Colors.green,
              selected: _filter == StockFilter.all,
              onTap: () => setState(() => _filter = StockFilter.all),
            ),
            const SizedBox(width: 10),

            _FilterChip(
              label: "Low Stock",
              color: Colors.orange,
              selected: _filter == StockFilter.low,
              onTap: () => setState(() => _filter = StockFilter.low),
            ),
            const SizedBox(width: 10),

            _FilterChip(
              label: "Out of Stock",
              color: Colors.red,
              selected: _filter == StockFilter.out,
              onTap: () => setState(() => _filter = StockFilter.out),
            ),
            const SizedBox(width: 10),

            _FilterChip(
              label: "Nearly Expiry",
              color: Colors.yellow[800]!,
              selected: _filter == StockFilter.expiry,
              onTap: () => setState(() => _filter = StockFilter.expiry),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // ---------------- TABLE CONTAINER ----------------
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8B5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                // TABLE HEADER
                Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _HeaderCell("Item", flex: 2)),
                      Expanded(child: _HeaderCell("Category", flex: 2)),
                      Expanded(child: _HeaderCell("Quantity", flex: 2)),
                      Expanded(child: _HeaderCell("Expiry", flex: 2)),
                      Expanded(child: _HeaderCell("QR Code", flex: 2)),
                      Expanded(child: _HeaderCell("Status", flex: 2)),
                    ],
                  ),
                ),

                // BODY (Provider-powered)
                Expanded(
                  child: Consumer<InventoryProvider>(
                    builder: (context, inventory, _) {
                      if (inventory.loading && inventory.items.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 🔹 APPLY FILTER HERE
                      final List<ItemModel> filteredItems = () {
                        List<ItemModel> base;

                        switch (_filter) {
                          case StockFilter.low:
                            base =
                                inventory.items
                                    .where((i) => i.isLowStock)
                                    .toList();
                            break;

                          case StockFilter.out:
                            base =
                                inventory.items
                                    .where((i) => i.isOutOfStock)
                                    .toList();
                            break;

                          case StockFilter.expiry:
                            final now = DateTime.now();
                            base =
                                inventory.items.where((i) {
                                  final exp = i.nearestExpiry;
                                  return exp != null &&
                                      exp.difference(now).inDays <= 30;
                                }).toList();
                            break;

                          case StockFilter.all:
                            base = inventory.items;
                        }

                        // 🔍 APPLY SEARCH
                        if (_searchQuery.isEmpty) return base;

                        return base.where((item) {
                          return item.name.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              item.category.toLowerCase().contains(
                                _searchQuery,
                              );
                        }).toList();
                      }();

                      if (filteredItems.isEmpty) {
                        return const Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      return NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!inventory.loading &&
                              inventory.hasMore &&
                              scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200) {
                            inventory.fetchItems();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount:
                              filteredItems.length +
                              (inventory.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredItems.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = filteredItems[index];

                            return StockRow(
                              item: item.name,
                              category: item.category,
                              qty: item.totalStock,
                              expiry: item.nearestExpiryFormatted,
                              barcodeUrl: item.barcodeImageUrl,
                              itemModel: item,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//
// ========================= FILTER CHIP =========================
//
class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.3) : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: selected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

//
// ========================= TABLE HEADER =========================
//
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

//
// ========================= STOCK ROW =========================
//
class StockRow extends StatelessWidget {
  final String item;
  final String category;
  final int qty;
  final String expiry;
  final String? barcodeUrl;
  final ItemModel itemModel; // 🔑 pass whole item

  const StockRow({
    super.key,
    required this.item,
    required this.category,
    required this.qty,
    required this.expiry,
    required this.itemModel,
    this.barcodeUrl,
  });

  String _getStatus() {
    if (itemModel.isOutOfStock) {
      return "Out of Stock";
    }

    if (itemModel.isLowStock) {
      return "Low Stock";
    }

    final expiryDate = itemModel.nearestExpiry;
    if (expiryDate != null &&
        expiryDate.difference(DateTime.now()).inDays <= 30) {
      return "Nearly Expiry";
    }

    return "Good";
  }

  Color _statusColor() {
    switch (_getStatus()) {
      case "Out of Stock":
        return Colors.red;
      case "Low Stock":
        return Colors.orange;
      case "Nearly Expiry":
        return Colors.yellow[800]!;
      default:
        return Colors.green[900]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green[700]!, width: 1.2),
      ),
      child: Row(
        children: [
          _Cell(item, flex: 2),
          _Cell(category, flex: 2),
          _Cell(qty.toString(), flex: 2),
          _Cell(expiry, flex: 2),

          // ================= BARCODE CELL =================
          _Cell(
            null,
            flex: 2,
            child:
                barcodeUrl == null
                    ? const Icon(Icons.qr_code, color: Colors.grey)
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.network(
                          barcodeUrl!,
                          height: 70,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.red,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green[700]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => _BarcodeViewerDialog(
                                      name: item,
                                      barcodeUrl: barcodeUrl!,
                                    ),
                              );
                            },
                            child: Text(
                              "View",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),

          // ================= STATUS CELL =================
          _Cell(
            null,
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _statusColor()),
                  ),
                  child: Text(
                    _getStatus(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  icon: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.green,
                  ),
                  label: Text(
                    "Details",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ItemDetailsDialog(item: itemModel),
                    );
                  },
                ),
              ],
            ),
          ),

          // Delete button removed from row
        ],
      ),
    );
  }
}

class _BarcodeViewerDialog extends StatelessWidget {
  final String barcodeUrl;
  final String name;

  const _BarcodeViewerDialog({required this.name, required this.barcodeUrl});

  Future<void> _saveImage(BuildContext context) async {
    try {
      // 1️⃣ Download image
      final response = await http.get(Uri.parse(barcodeUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to download image");
      }

      // 2️⃣ Ask WHERE to save
      final String? folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save the barcode',
      );

      if (folderPath == null) return; // user cancelled

      // 3️⃣ Create file path
      final fileName = 'QR_${name}.png';
      final filePath = '$folderPath/$fileName';

      // 4️⃣ Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;
      Navigator.pop(context); // close barcode preview dialog

      // 5️⃣ Feedback + open folder
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to:\n$filePath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openInExplorer(filePath),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save barcode: $e')));
    }
  }

  void _openInExplorer(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', file.path], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [file.parent.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.55;
    final width = MediaQuery.of(context).size.width * 0.55;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text(
                  "Barcode Preview",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ================= BARCODE IMAGE =================
            Container(
              height: height * 0.65,
              alignment: Alignment.center,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  barcodeUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.red,
                        size: 40,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================= ACTIONS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Align scanner to barcode",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _saveImage(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//
// ========================= TABLE CELL =========================
//
class _Cell extends StatelessWidget {
  final String? text;
  final int flex;
  final Widget? child;

  const _Cell(this.text, {required this.flex, this.child});

  String _formatCategory(String input) {
    final v = input.toLowerCase();

    if (v == "pgb") return "PGB";
    if (v == "bmcpgb") return "BMC";
    if (v == "dsbpgb") return "DSB";
    if (v == "bmc") return "BMC";
    if (v == "dsb") return "DSB";

    return input.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = text != null ? _formatCategory(text!) : null;

    return Expanded(
      flex: flex,
      child: Center(
        child:
            child ??
            Text(
              formatted!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}
