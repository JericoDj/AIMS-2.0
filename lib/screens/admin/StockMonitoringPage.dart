import 'package:aims2frontend/screens/admin/widgets/test/testBarcodeButton.dart';
import 'package:aims2frontend/screens/admin/widgets/test/testBarcodeToDesktop.dart';
import 'package:aims2frontend/screens/admin/widgets/test/testButton.dart';
import 'package:aims2frontend/screens/admin/widgets/test/testDecodeItem.dart';
import 'package:aims2frontend/screens/admin/widgets/test/testDecryptionButton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ItemModel.dart';
import '../../providers/items_provider.dart';
import 'dialogs/AddItemDialog.dart';
import 'dialogs/InventoryDialog.dart';
import 'dialogs/ItemDetailsDialog.dart';
import 'widgets/ReusableButton.dart';

class StockMonitoringPage extends StatefulWidget {
  const StockMonitoringPage({super.key});

  @override
  State<StockMonitoringPage> createState() => _StockMonitoringPageState();
}

class _StockMonitoringPageState extends State<StockMonitoringPage> {
  @override
  void initState() {
    super.initState();

    // Fetch inventory once when page opens
    Future.microtask(() {
      context.read<InventoryProvider>().fetchItems(refresh: true);
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
            const Text(
              "Stock Monitoring",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
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

                ReusableButton(
                  label: "Inventory\nReport",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const InventoryReportDialog(),
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
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search item...",
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            _FilterChip(label: "Low Stock", color: Colors.orange),
            const SizedBox(width: 10),
            _FilterChip(label: "Out of Stock", color: Colors.red),
            const SizedBox(width: 10),
            _FilterChip(label: "Nearly Expiry", color: Colors.yellow[800]!),
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
                    children: const [
                      _HeaderCell("Item", flex: 3),
                      _HeaderCell("Category", flex: 2),
                      _HeaderCell("Quantity", flex: 2),
                      _HeaderCell("Expiry", flex: 2),
                      _HeaderCell("QR Code", flex: 3),
                      _HeaderCell("Status", flex: 2),
                    ],
                  ),
                ),

                // BODY (Provider-powered)
                Expanded(
                  child: Consumer<InventoryProvider>(
                    builder: (context, inventory, _) {
                      if (inventory.loading && inventory.items.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (inventory.items.isEmpty) {
                        return const Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: inventory.items.length,
                        itemBuilder: (context, index) {
                          final item = inventory.items[index];

                          return StockRow(
                            item: item.name,
                            category: item.category,
                            qty: item.totalStock,
                            expiry: item.nearestExpiryFormatted,
                            barcodeUrl: item.barcodeImageUrl,
                            itemModel: item,

                          );
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
}

//
// ========================= FILTER CHIP =========================
//
class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
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
    if (qty == 0) return "Out of Stock";
    if (qty <= 10) return "Low Stock";

    final exp = DateTime.tryParse(expiry);
    if (exp != null && exp.difference(DateTime.now()).inDays <= 30) {
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
      height: 100,
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
          _Cell(item, flex: 3),
          _Cell(category, flex: 2),
          _Cell(qty.toString(), flex: 2),
          _Cell(expiry, flex: 2),

          // ================= BARCODE IMAGE CELL =================
          Expanded(
            flex: 3,
            child: barcodeUrl == null
                ? const Icon(Icons.qr_code, color: Colors.grey)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Small preview
                Image.network(
                  barcodeUrl!,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 4),

                // View button
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _BarcodeViewerDialog(
                        barcodeUrl: barcodeUrl!,
                      ),
                    );
                  },
                  child: const Text(
                    "View",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),


          // ================= STATUS =================
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
          ),

      Expanded(
        flex: 2,
        child: TextButton.icon(
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text("Details"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ItemDetailsDialog(item: itemModel),
            );
          },
        ),
      )],
      ),
    );
  }
}


class _BarcodeViewerDialog extends StatelessWidget {
  final String barcodeUrl;

  const _BarcodeViewerDialog({required this.barcodeUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const SizedBox(height: 10),

          // Large barcode image
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  barcodeUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Align scanner to barcode",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),
        ],
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
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
