import 'package:aims2frontend/screens/Offline/widgets/offline_transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/TransactionModel.dart';
import '../../providers/offline_transaction_provider.dart';
import '../admin/widgets/transaction_row.dart';

class OfflineTransactionsPage extends StatefulWidget {
  const OfflineTransactionsPage({super.key});

  @override
  State<OfflineTransactionsPage> createState() =>
      _OfflineTransactionsPageState();
}

class _OfflineTransactionsPageState extends State<OfflineTransactionsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineTransactionsProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<OfflineTransactionsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // ================= TITLE =================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Transactions",
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
          ],
        ),

        const SizedBox(height: 20),

        // ================= SEARCH + FILTER =================
        Row(
          children: const [
            Expanded(child: _SearchField()),
            SizedBox(width: 20),
            _TypeFilter(),
          ],
        ),

        const SizedBox(height: 30),

        // ================= TABLE =================
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8B5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const _TableHeader(),

                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (txProvider.loading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (txProvider.transactions.isEmpty) {
                        return const Center(
                          child: Text(
                            "No offline transactions found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: txProvider.transactions.length,
                        itemBuilder: (_, index) {
                          final tx = txProvider.transactions[index];
                          return OfflineTransactionRow(tx: tx, onView: () {  }, onDelete: () {  },);
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


class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: const Row(
        children: [
          _HeaderText("Date", flex: 2),
          _HeaderText("Item", flex: 2),
          _HeaderText("Qty", flex: 2),
          _HeaderText("Type", flex: 2),
          _HeaderText("User", flex: 2),
          _HeaderText("Actions", flex: 2),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderText(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}



class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Search transaction...",
            icon: Icon(
                color: Colors.green,
                Icons.search),
          ),
        ),
      ),
    );
  }
}



class _TypeFilter extends StatelessWidget {
  const _TypeFilter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TransactionType>(
          hint: const Text("Filter Type"),
          items: TransactionType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (_) {}, // hook later
        ),
      ),
    );
  }
}
