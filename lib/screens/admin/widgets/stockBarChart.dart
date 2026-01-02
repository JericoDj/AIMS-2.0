import 'package:flutter/material.dart';

import '../../../models/ItemUsage.dart';
import '../DashboardPage.dart';

class StockBarChart extends StatelessWidget {
  final List<ItemUsage> data;

  const StockBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No data"));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / (data.length * 1.6);
        final spacing = barWidth * 0.6;

        return Column(
          children: [
            // -------- CHART --------
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final dx = details.localPosition.dx;
                  final index =
                  (dx / (barWidth + spacing)).floor();

                  if (index >= 0 && index < data.length) {
                    _showItemDialog(context, data[index]);
                  }
                },
                child: CustomPaint(
                  painter: StockChartPainter(data),
                  size: Size.infinite,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // -------- LABELS --------
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: data.map((e) {
                  return SizedBox(
                    width: barWidth + spacing,
                    child: Text(
                      e.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showItemDialog(BuildContext context, ItemUsage item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.itemName),
        content: Text(
          "Total dispensed this month:\n\n${item.totalDispensed} pcs",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
