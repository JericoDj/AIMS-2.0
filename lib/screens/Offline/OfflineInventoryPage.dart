import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/TransactionModel.dart';
import '../../providers/offline_transaction_provider.dart';
import '../../utils/enums/stock_actions_enum.dart';
import '../admin/DashboardPage.dart';
import '../admin/InventoryPage.dart';

import 'dialogs/offlineStockActionDialog.dart';


class OfflineInventoryPage extends StatefulWidget {
  const OfflineInventoryPage({super.key});

  @override
  State<OfflineInventoryPage> createState() => _OfflineInventoryPageState();
}

class _OfflineInventoryPageState extends State<OfflineInventoryPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineTransactionsProvider>().loadTransactions();
    });
  }

  void _openStockDialog(BuildContext context, StockActionMode mode) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => OfflineStockActionDialog(mode: mode),
    );
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
      default:
        return type.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ---------------- HEADER ----------------
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                "Offline Inventory",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "OFFLINE MODE – Local Database",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

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
            ],
          ),



          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.05,
          ),

          // ---------------- BOTTOM ROW ----------------
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Row(
              children: [
                // LEFT — RECENT OFFLINE TRANSACTIONS
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 4,
                        color: Colors.green[400]!,
                      ),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Offline Transactions",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: Consumer<OfflineTransactionsProvider>(
                            builder: (context, provider, _) {
                              final transactions = provider.latest(limit: 5);

                              if (transactions.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No offline transactions yet",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  final tx = transactions[index];

                                  return RecentTransactionRow(
                                    item: tx.itemName,
                                    action: _actionLabel(tx.type),
                                    user: tx.userName ?? 'Offline',
                                    qty: tx.quantity?.toString() ?? '-',
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
