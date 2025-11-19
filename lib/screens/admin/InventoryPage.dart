import 'package:flutter/material.dart';

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
                label: "Delete Stock",
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ---------------- BOTTOM ROW ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              InventoryButton(
                icon: Icons.edit_note,
                label: "Create Item",
              ),
              SizedBox(width: 40),
              InventoryButton(
                icon: Icons.delete,
                label: "Remove Item",
              ),
            ],
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
