import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingActions extends StatelessWidget {
  const LandingActions({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        /// LOGIN BUTTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionButton(
              label: "Login as Admin",
              color: Colors.green,
              onTap: () => context.go('/login/admin'),
            ),

            SizedBox(width: width * 0.1),

            _ActionButton(
              label: "Login as User",
              color: Colors.green,
              onTap: () => context.go('/login/user'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// OFFLINE MODE
        _ActionButton(
          label: "Offline Mode",
          color: Colors.red,
          onTap: () => {
            print("Navigating to offline mode"),
            context.go('/offline'),

    }
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
