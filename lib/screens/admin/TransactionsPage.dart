  import 'dart:io';

import 'package:aims2frontend/screens/admin/widgets/transaction_row.dart';
  import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
  import 'package:provider/provider.dart';

  import '../../models/TransactionModel.dart';
  import '../../providers/transactions_provider.dart';
  import 'widgets/ReusableButton.dart';

  import 'package:pdf/widgets.dart' as pw;
  import 'package:printing/printing.dart';



  class TransactionsPage extends StatefulWidget {

    final String? initialSearch;


    const TransactionsPage({
      this.initialSearch,
      super.key});

    @override
    State<TransactionsPage> createState() => _TransactionsPageState();
  }

  class _TransactionsPageState extends State<TransactionsPage> {

    String _searchQuery = '';
    TransactionType? _selectedType;

    @override
    void initState() {
      super.initState();

      if (widget.initialSearch != null &&
          widget.initialSearch!.isNotEmpty) {
        _searchQuery = widget.initialSearch!.toLowerCase();
      }

      Future.microtask(() {
        context.read<TransactionsProvider>().fetchTransactions(refresh: true);
      });
    }

    void showViewTransactionDialog(
        BuildContext context,
        InventoryTransaction tx,
        ) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Transaction Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row("Item", tx.itemName),
              _row("Type", tx.type.name),
              _row("Quantity", tx.quantity?.toString() ?? '-'),
              _row("User", tx.userName ?? '-'),

            ],
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    Widget _row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text("$label:")),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }


    void showDeleteTransactionDialog(
        BuildContext context,
        InventoryTransaction tx,
        VoidCallback onConfirm,
        ) {
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
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Delete"),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
            ),
          ],
        ),
      );
    }

    void showTransactionReportDialog(BuildContext context) {
      final now = DateTime.now();

      DateTime startDate = DateTime(now.year, now.month, 1);
      DateTime endDate = now;

      Future<void> pickDate(
          BuildContext ctx,
          bool isStart,
          void Function(VoidCallback) setState,
          ) async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: isStart ? startDate : endDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          setState(() {
            if (isStart) {
              startDate = picked;
            } else {
              endDate = picked;
            }
          });
        }
      }

      showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text("Transaction Report"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Start Date"),
                  subtitle: Text(_fmt(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => pickDate(ctx, true, setState),
                ),
                ListTile(
                  title: const Text("End Date"),
                  subtitle: Text(_fmt(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => pickDate(ctx, false, setState),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                child: const Text("Generate PDF"),
                onPressed: () {
                  Navigator.pop(ctx);
                  generateTransactionPdf(
                    context,
                    startDate,
                    endDate,
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    String _fmt(DateTime d) => d.toIso8601String().split('T').first;

    Future<void> generateTransactionPdf(
        BuildContext context,
        DateTime start,
        DateTime end,
        ) async {
      final provider = context.read<TransactionsProvider>();

      final transactions = provider.transactions.where((tx) {
        final date = tx.timestamp;
        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();

      // ================= GROUP TOTALS =================
      final Map<String, int> totalAdded = {};
      final Map<String, int> totalDispensed = {};

      for (final tx in transactions) {
        final item = tx.itemName;
        final qty = tx.quantity ?? 0;

        if (tx.type == TransactionType.addStock) {
          totalAdded[item] = (totalAdded[item] ?? 0) + qty;
        } else if (tx.type == TransactionType.dispense) {
          totalDispensed[item] = (totalDispensed[item] ?? 0) + qty;
        }
      }

      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (_) => [
            // ================= HEADER =================
            pw.Text(
              'Transaction Report',
              style: pw.TextStyle(font: boldFont, fontSize: 22),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'From ${dateFormat.format(start)} to ${dateFormat.format(end)}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.SizedBox(height: 20),

            // ================= TRANSACTION TABLE =================
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.SizedBox(height: 6),

            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 11),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              headers: const ['Date', 'Item', 'Qty', 'Type', 'User'],
              data: transactions.map((tx) {
                return [
                  dateFormat.format(tx.timestamp),
                  tx.itemName,
                  tx.quantity?.toString() ?? '-',
                  tx.type.name.toUpperCase(),
                  tx.userName ?? 'System',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 30),

            // ================= SUMMARY =================
            pw.Text(
              'Item Summary',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 11),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              headers: const [
                'Item',
                'Total Added',
                'Total Dispensed',
              ],
              data: totalAdded.keys.map((item) {
                return [
                  item,
                  totalAdded[item]?.toString() ?? '0',
                  totalDispensed[item]?.toString() ?? '0',
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();

      // ================= PREVIEW + SAVE =================
      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 900,
            height: 650,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction Report Preview',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Save'),
                            onPressed: () async {
                              final dir =
                              await getApplicationDocumentsDirectory();
                              final file = File(
                                '${dir.path}/transaction_report_${dateFormat.format(start)}_${dateFormat.format(end)}.pdf',
                              );
                              await file.writeAsBytes(pdfBytes);

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Saved to ${file.path}'),
                                ),
                              );
                            },
                          ),
                          TextButton(
                            child: const Text('Close'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (_) async => pdfBytes,
                    allowPrinting: false,
                    allowSharing: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }





    void showGeneratedReportDialog(
        BuildContext context,
        DateTime start,
        DateTime end,
        ) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Report Generated"),
          content: Text(
            "Transactions from:\n\n"
                "${start.toIso8601String().split('T').first} → "
                "${end.toIso8601String().split('T').first}",
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }





    @override
    Widget build(BuildContext context) {
      final txProvider = context.watch<TransactionsProvider>();

      final filteredTransactions = txProvider.transactions.where((tx) {
        // TYPE FILTER
        if (_selectedType != null && tx.type != _selectedType) {
          return false;
        }

        // SEARCH FILTER
        if (_searchQuery.isNotEmpty) {
          return tx.itemName.toLowerCase().contains(_searchQuery) ||
              (tx.userName ?? '').toLowerCase().contains(_searchQuery) ||
              tx.type.name.toLowerCase().contains(_searchQuery);
        }

        return true;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ---------------- PAGE TITLE ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Transactions",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              ReusableButton(
                label: "Transaction\nReport",
                onTap: () => showTransactionReportDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------- SEARCH + FILTER ----------------
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search transaction...",
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _TypeFilter(
                value: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
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
                  const _TableHeader(),

                  Expanded(
                    child: txProvider.loading &&
                        txProvider.transactions.isEmpty
                        ? const Center(
                      child: CircularProgressIndicator(),
                    )
                        : filteredTransactions.isEmpty
                        ? const Center(
                      child: Text(
                        "No transactions found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (_, index) {
                        final tx = filteredTransactions[index];
                        return TransactionRow(
                          tx: tx,

                          onView: () {
                            showViewTransactionDialog(context, tx);
                          },

                          onDelete: () {
                            showDeleteTransactionDialog(
                              context,
                              tx,
                                  () async {
                                await context
                                    .read<TransactionsProvider>()
                                    .deleteTransaction(tx.id);
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
        ],
      );
    }
  }

    class _TypeFilter extends StatelessWidget {
    final TransactionType? value;
    final ValueChanged<TransactionType?> onChanged;

    const _TypeFilter({
      required this.value,
      required this.onChanged,
    });

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
            value: value,
            hint: const Text("Filter Type"),
            items: [
              const DropdownMenuItem<TransactionType>(
                value: null,
                child: Text("ALL"),
              ),
              ...TransactionType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ),
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
            _HeaderText("Item", flex: 3),
            _HeaderText("Qty", flex: 1),
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




