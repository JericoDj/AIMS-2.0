import 'package:flutter/material.dart';
import '../../../models/TransactionModel.dart';
class OfflineTransactionRow extends StatelessWidget {
  final InventoryTransaction tx;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const OfflineTransactionRow({
    super.key,
    required this.tx,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.green,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _CellText(
            tx.timestamp.toIso8601String().split('T').first,
            flex: 2,
          ),
          _CellText(tx.itemName, flex: 2),
          _CellText(tx.quantity?.toString() ?? '-', flex: 2),
          _CellText(tx.type.name.toUpperCase(), flex: 2),
          _CellText(tx.userName ?? 'System', flex: 2),

          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,

              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onView,
                  child: Text(
                    "View",
                    style: TextStyle(
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                GestureDetector(
                  onTap: onDelete,
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // ================= VIEW DIALOG =================
  void _showViewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Transaction Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail("Item", tx.itemName),
            _detail("Type", tx.type.name),
            _detail("Quantity", tx.quantity?.toString() ?? '-'),
            _detail("User", tx.userName ?? 'System'),
            _detail(
              "Date",
              tx.timestamp.toIso8601String().split('T').first,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ================= DELETE CONFIRM =================
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
          "Are you sure you want to delete this transaction?\n\n"
              "Item: ${tx.itemName}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ================= CELL TEXT =================
class _CellText extends StatelessWidget {
  final String text;
  final int flex;

  const _CellText(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(

      flex: flex,
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: TextStyle(
          fontSize: 17,
          color: Colors.green[900],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
