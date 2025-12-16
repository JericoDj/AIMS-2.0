import 'package:flutter/material.dart';

import 'widgets/ReportsButton.dart';

class StockMonitoringPage extends StatelessWidget {
  const StockMonitoringPage({super.key});

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

            ReportButton(
              label: "Inventory\nReport",
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

            // LOW STOCK FILTER
            _FilterChip(label: "Low Stock", color: Colors.orange),

            const SizedBox(width: 10),

            // OUT OF STOCK FILTER
            _FilterChip(label: "Out of Stock", color: Colors.red),

            const SizedBox(width: 10),

            // NEAR EXPIRY FILTER
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
                      _HeaderCell("Status", flex: 2),
                    ],
                  ),
                ),

                // BODY
                Expanded(
                  child: ListView(
                    children: const [
                      StockRow(
                        item: "Paracetamol",
                        category: "Medicine",
                        qty: 5,
                        expiry: "2025-01-15",
                      ),
                      StockRow(
                        item: "Ibuprofen",
                        category: "Medicine",
                        qty: 0,
                        expiry: "2024-12-01",
                      ),
                      StockRow(
                        item: "Vitamin C",
                        category: "Supplement",
                        qty: 45,
                        expiry: "2024-12-29",
                      ),
                      StockRow(
                        item: "Amoxicillin",
                        category: "Antibiotic",
                        qty: 12,
                        expiry: "2025-09-10",
                      ),
                    ],
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
// ========================= STOCK ROW WIDGET =========================
//
class StockRow extends StatelessWidget {
  final String item;
  final String category;
  final int qty;
  final String expiry;

  const StockRow({
    super.key,
    required this.item,
    required this.category,
    required this.qty,
    required this.expiry,
  });

  // Stock status logic
  String _getStatus() {
    if (qty == 0) return "Out of Stock";
    if (qty <= 10) return "Low Stock";

    // Simulate "nearly expiry" by example
    // In real logic we compare date difference
    DateTime today = DateTime.now();
    DateTime exp = DateTime.parse(expiry);
    if (exp.difference(today).inDays <= 30) {
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
      height: 60,
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

          // STATUS BADGE
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _statusColor(),
                  width: 1,
                ),
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
