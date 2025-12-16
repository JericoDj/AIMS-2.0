import 'package:flutter/material.dart';

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
        width: MediaQuery.sizeOf(context).width * 0.1,
        height: MediaQuery.sizeOf(context).width * 0.06,
        decoration: BoxDecoration(
          color: const Color(0xFFD0E8B5), // light green
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green[900],
              fontSize:MediaQuery.sizeOf(context).width * 0.012,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
