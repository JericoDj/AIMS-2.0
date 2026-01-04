import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/ItemUsage.dart';


class TopDispensedBarChart extends StatelessWidget {
  final List<ItemUsage> data;
  final void Function(ItemUsage item)? onItemTap;

  const TopDispensedBarChart({
    super.key,
    required this.data,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No data"));
    }

    final maxValue =
    data.map((e) => e.totalDispensed).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxValue.toDouble() * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItem: (group, _, rod, __) {
              final item = data[group.x.toInt()];
              return BarTooltipItem(
                '${item.itemName}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${item.totalDispensed} pcs',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              );
            },
          ),

          // 🔑 CLICK ONLY (not hover)
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return; // ❗ ONLY CLICK

            if (response == null || response.spot == null) return;

            final index = response.spot!.touchedBarGroupIndex;

            if (index < 0 || index >= data.length) return;

            onItemTap?.call(data[index]);
          },
        ),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index].itemName,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
              (index) {
            final item = data[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.totalDispensed.toDouble(),
                  color: Colors.green[700],
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          },
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }
}
