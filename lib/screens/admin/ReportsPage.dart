import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ReportButton(
            label: "Inventory\nReport",
          ),
          SizedBox(width: 80),
          ReportButton(
            label: "Transaction\nReport",
          ),
        ],
      ),
    );
  }
}

//
// ---------------- REUSABLE REPORT BUTTON ----------------
//
class ReportButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const ReportButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 260,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFD0E8B5), // light green
          borderRadius: BorderRadius.circular(35),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green[900],
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
