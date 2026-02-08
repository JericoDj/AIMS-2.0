import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/TransactionModel.dart';
import '../../providers/transactions_provider.dart';

import '../../utils/enums/stock_actions_enum.dart';
import 'DashboardPage.dart';
import 'dialogs/StockActionDialog.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ---------------- TOP ROW ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InventoryButton(
                icon: Icons.search,
                label: "View Stock",
                onTap: () {
                  _openStockDialog(context, StockActionMode.view);
                },
              ),

              const SizedBox(width: 40),

              InventoryButton(
                icon: Icons.add,
                label: "Add Stock",
                onTap: () {
                  _openStockDialog(context, StockActionMode.add);
                },
              ),

              const SizedBox(width: 40),

              InventoryButton(
                icon: Icons.remove_circle_outline,
                label: "Dispense Stock",
                onTap: () {
                  _openStockDialog(context, StockActionMode.dispense);
                },
              ),

              // ---------------- DELETE BUTTON MOVED TO VIEW DIALOG ----------------
            ],
          ),

          // ---------------- BOTTOM ROW ----------------
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),

          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: Row(
              children: [
                // LEFT — RECENT TRANSACTIONS
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      border: Border.all(width: 4, color: Colors.green[400]!),

                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: Consumer<TransactionsProvider>(
                            builder: (context, provider, _) {
                              return StreamBuilder<List<InventoryTransaction>>(
                                stream: provider.watchLatest(limit: 5),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "No recent transactions",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }

                                  final transactions = snapshot.data!;

                                  return ListView.builder(
                                    itemCount: transactions.length,
                                    itemBuilder: (context, index) {
                                      final tx = transactions[index];

                                      return RecentTransactionRow(
                                        item: tx.itemName,
                                        action: _actionLabel(tx.type),
                                        user: tx.userName ?? 'Unknown',
                                        qty: tx.quantity?.toString() ?? '-',
                                      );
                                    },
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

                const SizedBox(width: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _actionLabel(TransactionType type) {
  switch (type) {
    case TransactionType.addStock:
      return 'Added';
    case TransactionType.dispense:
      return 'Dispensed';
    case TransactionType.createItem:
      return 'Created';
    case TransactionType.deleteItem:
      return 'Deleted';
    // default not needed if we cover all cases, but if type is dynamic or external, safe to keep.
    // Lint said default is covered by previous cases? Wait, if enum has 4 values and I used 4 cases, then default is redundant.
  }
  return type.name;
}

void _openStockDialog(BuildContext context, StockActionMode mode) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => StockActionDialog(mode: mode),
  );
}

//
// ---------------- REUSABLE BUTTON WIDGET ----------------
//
class InventoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;
  final Color? borderColor;

  const InventoryButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.iconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 210,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(
            width: 3,
            color: borderColor ?? Colors.green[600]!,
          ),
          color: color ?? Colors.green[50],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 55, color: iconColor ?? Colors.green[600]),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color:
                    iconColor != null
                        ? (iconColor!.withOpacity(0.8))
                        : Colors.green[700],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
