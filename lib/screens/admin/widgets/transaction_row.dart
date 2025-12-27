import 'package:flutter/material.dart';

import '../../../models/TransactionModel.dart';

class TransactionRow extends StatelessWidget {
  final InventoryTransaction tx;

  const TransactionRow({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.7),
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
          _CellText(tx.itemName, flex: 3),
          _CellText(tx.quantity?.toString() ?? '-', flex: 1),
          _CellText(tx.type.name.toUpperCase(), flex: 2),
          _CellText(tx.userName ?? 'System', flex: 2),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: View dialog
                  },
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
                  onTap: () {
                    // TODO: Delete (admin-only)
                  },
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.green[900],
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
}


class _CellText extends StatelessWidget { final String text; final int flex; const _CellText(this.text, {required this.flex}); @override Widget build(BuildContext context) { return Expanded( flex: flex, child: Text( text, style: TextStyle( fontSize: 17, color: Colors.green[900], fontWeight: FontWeight.w500, ), ), ); } }
