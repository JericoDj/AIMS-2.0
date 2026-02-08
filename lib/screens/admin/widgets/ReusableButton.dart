import 'package:flutter/material.dart';

//
// ---------------- REUSABLE REPORT BUTTON ----------------
//
class ReusableButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const ReusableButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.green;
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.1,
        height: MediaQuery.sizeOf(context).width * 0.06,
        decoration: BoxDecoration(
          border: Border.all(color: baseColor, width: 2),
          color: baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: baseColor,
              fontSize: MediaQuery.sizeOf(context).width * 0.012,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
