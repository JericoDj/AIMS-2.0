import 'package:flutter/material.dart';

//
// ---------------- REUSABLE REPORT BUTTON ----------------
//
class ReusableButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const ReusableButton({
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
          border: Border.all(
            color: Colors.green[600]!,
            width: 2,
          ),
          color: Colors.green[50], // light green
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
