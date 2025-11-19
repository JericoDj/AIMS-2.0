import 'package:flutter/material.dart';

class OfflineStockMonitoringPage extends StatelessWidget {
  const OfflineStockMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Offline Stock Monitoring",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "OFFLINE MODE – Local Database",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 30),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFFD0E8B5),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Text(
              "Offline Stock Monitoring UI Here",
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
