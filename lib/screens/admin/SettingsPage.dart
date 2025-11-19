import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
              SettingsButton(label: "User\nGuide"),
              SizedBox(width: 60),
              SettingsButton(label: "Back Up\nand Reset"),
            ],
          ),

          const SizedBox(height: 60),

          // ---------------- BOTTOM ROW ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SettingsButton(label: "System\nConfiguration"),
              SizedBox(width: 60),
              SettingsButton(label: "System\nVersion Info."),
            ],
          ),
        ],
      ),
    );
  }
}

//
// ------------------- REUSABLE BUTTON -------------------
//
class SettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SettingsButton({
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
          color: const Color(0xFFD0E8B5), // soft green
          borderRadius: BorderRadius.circular(35),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green[900],
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
