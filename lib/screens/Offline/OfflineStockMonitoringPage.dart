import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


import '../../models/ItemModel.dart';
import '../../providers/offline_inventory_provider.dart';
import '../../utils/enums/stock_filter_enum.dart';
import '../admin/dialogs/OfflineItemDialog.dart';
import '../admin/widgets/ReusableButton.dart';


class OfflineStockMonitoringPage extends StatefulWidget {
  const OfflineStockMonitoringPage({super.key});

  @override
  State<OfflineStockMonitoringPage> createState() => _OfflineStockMonitoringPageState();
}

class _OfflineStockMonitoringPageState extends State<OfflineStockMonitoringPage> {
  StockFilter _filter = StockFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineInventoryProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // ---------------- PAGE TITLE ----------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stock Monitoring",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  "OFFLINE MODE – Local Database",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                ReusableButton(
                  label: "Add\nItem",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const OfflineAddItemDialog(),
                    );
                  },
                ),

                const SizedBox(width: 10),

                // ReusableButton(
                //   label: "Inventory\nReport",
                //   onTap: () {
                //     showDialog(
                //       context: context,
                //       builder: (_) =>
                //       const OfflineInventoryReportDialog(),
                //     );
                //   },
                // ),
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
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child:  Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search item...",
                      icon: Icon(Icons.search),
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
              color: Colors.yellow,
              selected: _filter == StockFilter.expiry,
              onTap: () => setState(() => _filter = StockFilter.expiry),
            ),

          ],
        ),

        const SizedBox(height: 30),

        // ---------------- TABLE ----------------
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8B5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                _tableHeader(),

                Expanded(
                  child: Consumer<OfflineInventoryProvider>(
                    builder: (context, inventory, _) {
                      if (inventory.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<ItemModel> filteredItems = () {
                        List<ItemModel> base;

                        switch (_filter) {
                          case StockFilter.low:
                            base = inventory.items.where((i) => i.isLowStock).toList();
                            break;

                          case StockFilter.out:
                            base = inventory.items.where((i) => i.isOutOfStock).toList();
                            break;

                          case StockFilter.expiry:
                            final now = DateTime.now();
                            base = inventory.items.where((i) {
                              final exp = i.nearestExpiry;
                              return exp != null && exp.difference(now).inDays <= 30;
                            }).toList();
                            break;

                          case StockFilter.all:
                          default:
                            base = inventory.items;
                        }

                        if (_searchQuery.isEmpty) return base;

                        return base.where((item) {
                          return item.name.toLowerCase().contains(_searchQuery) ||
                              item.category.toLowerCase().contains(_searchQuery);
                        }).toList();
                      }();

                      if (filteredItems.isEmpty) {
                        return const Center(
                          child: Text("No offline items found", style: TextStyle(fontSize: 18)),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return OfflineStockRow(item: item);
                        },
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

  Widget _tableHeader() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: const Row(
        children: [
          _HeaderCell("Item", flex: 2),
          _HeaderCell("Category", flex: 2),
          _HeaderCell("Quantity", flex: 2),
          _HeaderCell("Expiry", flex: 2),
          _HeaderCell("QR Code", flex: 2),
          _HeaderCell("Status", flex: 2),
        ],
      ),
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
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
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
    return Expanded(
      flex: flex,
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}


//
// ========================= STOCK ROW =========================
//
class OfflineStockRow extends StatelessWidget {
  final ItemModel item;

  const OfflineStockRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.7),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _Cell(item.name, flex: 2),
          _Cell(item.category, flex: 2),
          _Cell(item.displayStock.toString(), flex: 2),
          _Cell(item.nearestExpiryFormatted, flex: 2),

          Expanded(
            flex: 2,
            child: _QrCell(item: item),
          ),

          Expanded(
            flex: 2,
            child:_StatusBadge(item: item),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ItemModel item;

  const _StatusBadge({required this.item});

  String _statusText() {
    if (item.hasExcess) return "Excess Usage";
    if (item.totalStock == 0) return "Out of Stock";
    if (item.totalStock <= item.lowStockThreshold) return "Low Stock";
    return "Good";
  }

  Color _statusColor() {
    if (item.hasExcess) return Colors.purple;
    if (item.totalStock == 0) return Colors.red;
    if (item.totalStock <= item.lowStockThreshold) return Colors.orange;
    return Colors.green[900]!;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        _statusText(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
class _QrCell extends StatelessWidget {
  final ItemModel item;

  const _QrCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final barcodeUrl = item.barcodeImageUrl;

    return Expanded(
      flex: 2,
      child: barcodeUrl == null || barcodeUrl.isEmpty
          ? const Icon(Icons.qr_code, color: Colors.grey)
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ================= SMALL PREVIEW =================
          SizedBox(
            height: 70,
            child: barcodeUrl.startsWith('/')
                ? Image.file(
              File(barcodeUrl),
              fit: BoxFit.contain,
            )
                : Image.network(
              barcodeUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= VIEW BUTTON =================
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) =>
                    _BarcodeViewerDialog(barcodeUrl: barcodeUrl),
              );
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[700]!),
                borderRadius: BorderRadius.circular(6),
              ),
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
    );
  }
}

class _BarcodeViewerDialog extends StatelessWidget {
  final String barcodeUrl;

  const _BarcodeViewerDialog({required this.barcodeUrl});

  Future<void> _saveImage(BuildContext context) async {
    try {
      // 1️⃣ Download image
      final response = await http.get(Uri.parse(barcodeUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to download image");
      }

      // 2️⃣ Ask WHERE to save
      final String? folderPath =
      await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save the QR / Barcode',
      );

      if (folderPath == null) return;

      // 3️⃣ Create file
      final fileName =
          'barcode_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$folderPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;
      Navigator.pop(context);

      // 4️⃣ Success feedback
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

  void _openInExplorer(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    if (Platform.isWindows) {
      await Process.run(
        'explorer',
        ['/select,', file.path],
        runInShell: true,
      );
    } else if (Platform.isMacOS) {
      await Process.run(
        'open',
        ['-R', file.path],
      );
    } else if (Platform.isLinux) {
      await Process.run(
        'xdg-open',
        [file.parent.path],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.45;
    final width = MediaQuery.of(context).size.width * 0.45;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text(
                  "QR / Barcode Preview",
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

            // ================= IMAGE =================
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: barcodeUrl.startsWith('/')
                    ? Image.file(
                  File(barcodeUrl),
                  fit: BoxFit.contain,
                )
                    : Image.network(
                  barcodeUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image,
                      color: Colors.red, size: 40),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================= ACTIONS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Align scanner to code",
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
  final String text;
  final int flex;

  const _Cell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    final isNegative = text.startsWith('-');

    return Expanded(
      flex: flex,
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: TextStyle(
          color: isNegative ? Colors.purple : Colors.green[900],
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


