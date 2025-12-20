import 'package:flutter/material.dart';

import 'widgets/ReusableButton.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

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
              "Transactions",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            ReusableButton(
              label: "Transaction\nReport",
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ---------------- SEARCH + FILTER ROW ----------------
        Row(
          children: [
            // Search field
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
                      hintText: "Search transaction...",
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Filter dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text("Filter Type"),
                  items: const [
                    DropdownMenuItem(
                      value: "add",
                      child: Text("Add Stock"),
                    ),
                    DropdownMenuItem(
                      value: "remove",
                      child: Text("Remove Stock"),
                    ),
                    DropdownMenuItem(
                      value: "update",
                      child: Text("Update Item"),
                    ),
                  ],
                  onChanged: (value) {},
                ),
              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: const [
                      _HeaderText("Date", flex: 2),
                      _HeaderText("Item", flex: 3),
                      _HeaderText("Qty", flex: 1),
                      _HeaderText("Type", flex: 2),
                      _HeaderText("User", flex: 2),
                      _HeaderText("Actions", flex: 2),
                    ],
                  ),
                ),

                // TABLE BODY (FAKE SAMPLE DATA)
                Expanded(
                  child: ListView(
                    children: const [
                      TransactionRow(
                        date: "2025-11-10",
                        item: "Paracetamol",
                        qty: "100",
                        type: "Add Stock",
                        user: "Jerico De Jesus",
                      ),
                      TransactionRow(
                        date: "2025-11-10",
                        item: "Biogesic",
                        qty: "50",
                        type: "Remove Stock",
                        user: "Baby Jane",
                      ),
                      TransactionRow(
                        date: "2025-11-09",
                        item: "Vitamin C",
                        qty: "200",
                        type: "Add Stock",
                        user: "Mhiel James",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

//
// =================== HEADER TEXT WIDGET ===================
//
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

//
// =================== TRANSACTION ROW WIDGET ===================
//
class TransactionRow extends StatelessWidget {
  final String date;
  final String item;
  final String qty;
  final String type;
  final String user;

  const TransactionRow({
    super.key,
    required this.date,
    required this.item,
    required this.qty,
    required this.type,
    required this.user,
  });

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
          _CellText(date, flex: 2),
          _CellText(item, flex: 3),
          _CellText(qty, flex: 1),
          _CellText(type, flex: 2),
          _CellText(user, flex: 2),

          // ACTION BUTTONS
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
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
                  onTap: () {},
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
          )
        ],
      ),
    );
  }
}

//
// =================== CELL TEXT (BODY) ===================
//
class _CellText extends StatelessWidget {
  final String text;
  final int flex;

  const _CellText(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
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
