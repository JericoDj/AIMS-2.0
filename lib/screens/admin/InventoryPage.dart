import 'package:flutter/material.dart';

import 'DashboardPage.dart';

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
            children: const [
              InventoryButton(
                icon: Icons.search,
                label: "View Stock",
              ),
              SizedBox(width: 40),
              InventoryButton(
                icon: Icons.add,
                label: "Add Stock",
              ),
              SizedBox(width: 40),
              InventoryButton(
                icon: Icons.remove_circle_outline,
                label: "Dispense Stock",
              ),
            ],
          ),

          // ---------------- BOTTOM ROW ----------------


          SizedBox(
            height:  MediaQuery.sizeOf(context).height * 0.05,
          ),

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
                      border: Border.all(
                          width: 4,
                          color: Colors.green[400]!),

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
                          child: ListView(
                            children: const [
                              RecentTransactionRow(
                                item: "Paracetamol",
                                action: "Added",
                                user: "Jerico",
                                qty: "100",
                              ),
                              RecentTransactionRow(
                                item: "Biogesic",
                                action: "Removed",
                                user: "Baby Jane",
                                qty: "50",
                              ),
                              RecentTransactionRow(
                                item: "Vitamin C",
                                action: "Added",
                                user: "Mhiel",
                                qty: "200",
                              ),
                            ],
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

//
// ---------------- REUSABLE BUTTON WIDGET ----------------
//
class InventoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const InventoryButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 210,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFD0E8B5), // Light green like sample
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 55,
              color: Colors.green[900],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
