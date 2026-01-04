import 'package:aims2frontend/providers/notification_provider.dart';
import 'package:aims2frontend/screens/admin/widgets/topDispensedBarCharts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/dashboardAnalyticsController.dart';
import '../../models/ItemUsage.dart';
import '../../providers/items_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../utils/enums/stock_filter_enum.dart';

class DashboardPage extends StatefulWidget {
  final void Function(StockFilter filter)? onStatTap;
  final void Function(String itemName)? onChartItemTap;
  const DashboardPage({
    this.onStatTap,
    this.onChartItemTap,
    super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _initialized) return;
      _initialized = true;

      final inventory = context.read<InventoryProvider>();
      final transactions = context.read<TransactionsProvider>();

      await inventory.fetchItems(refresh: true);
      await transactions.fetchTransactions(refresh: true);
      // done via mailer send free tier
      // 🔔 Optional: trigger stock notification check here
      await inventory.checkAndSendStockNotifications(NotificationProvider());
    });
  }






  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final maxWidth = screen.width * 0.95;
    final maxHeight = screen.height * 0.90;

    return Center(
      child: Container(
        width: maxWidth,
        height: maxHeight,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ---------------- PAGE TITLE ----------------
              Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: maxHeight * 0.50,
                child: Row(
                  children: [
                    // LEFT — RECENT TRANSACTIONS




                    // RIGHT — STOCK CHART
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green[400]!,
                            width: 4

                          ),

                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Column(
                          children: [
                             Text(
                              "Current Month Usage Overview",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                            const SizedBox(height: 25),

                            Expanded(
                              child: Consumer<TransactionsProvider>(
                                builder: (context, txProvider, _) {
                                  final data =
                                  DashboardAnalyticsController.topDispensedItems(txProvider);

                                  if (data.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No dispense data this month',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }

                                  return TopDispensedBarChart(
                                    data: data,
                                    onItemTap: (item) {
                                      widget.onChartItemTap?.call(item.itemName);
                                    },
                                  );
                                },
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ---------------- TOP SUMMARY CARDS ----------------
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = constraints.maxWidth / 3 - 20;
                  double cardHeight = screen.height * 0.2;

                  return Consumer<InventoryProvider>(
                    builder: (context, inventory, _) {
                      final lowStockCount = inventory.lowStockItems.length;
                      final outOfStockCount =
                          inventory.items.where((i) => i.isOutOfStock).length;
                      final expiringSoonCount = inventory.nearlyExpiredItems.length;

                      return SizedBox(
                        height: cardHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ================= LOW STOCK =================
                            InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () => widget.onStatTap?.call(StockFilter.low),
                              child: DashboardStatCard(
                                title: "Low Stock",
                                value: lowStockCount.toString(),
                                icon: Icons.warning_amber_rounded,
                                iconColor: Colors.orange,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                            ),

                            // ================= OUT OF STOCK =================
                            InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () => widget.onStatTap?.call(StockFilter.out),
                              child: DashboardStatCard(
                                title: "Out of Stock",
                                value: outOfStockCount.toString(),
                                icon: Icons.error_outline,
                                iconColor: Colors.red,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                            ),

                            // ================= NEARLY EXPIRY =================
                            InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () => widget.onStatTap?.call(StockFilter.expiry),
                              child: DashboardStatCard(
                                title: "Expiring Soon",
                                value: expiringSoonCount.toString(),
                                icon: Icons.timer_outlined,
                                iconColor: Colors.orange,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                            ),
                          ],
                        ),
                      );

                    },
                  );
                },
              ),

              const SizedBox(height: 40),

              // ---------------- MIDDLE SECTION ----------------



            ],
          ),
        ),
      ),
    );
  }
}

//
// ===================== RESPONSIVE STAT CARD =====================
//
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double width;
  final double height;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(

        border: Border.all(
            width: 3,
            color: Colors.green[400]!),
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: height * 0.18, color: iconColor ?? Colors.green[800]),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: height * 0.12,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: height * 0.10,
              color: Colors.green[900],
            ),
          ),
        ],
      ),
    );
  }
}

//
// ===================== TRANSACTION ROW =====================
class RecentTransactionRow extends StatelessWidget {
  final String item;
  final String action;
  final String user;
  final String qty;

  const RecentTransactionRow({
    super.key,
    required this.item,
    required this.action,
    required this.user,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[800],
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              action,
              style: TextStyle(
                fontSize: 16,
                color: action == "Removed" ? Colors.red : Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "$qty pcs",
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[900],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user,
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
// ===================== CHART PAINTER =====================

class StockChartPainter extends CustomPainter {
  final List<ItemUsage> data;

  StockChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barPaint = Paint()..color = Colors.green[700]!;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final maxValue =
    data.map((e) => e.totalDispensed).reduce((a, b) => a > b ? a : b);

    final barWidth = size.width / (data.length * 1.6);
    final spacing = barWidth * 0.6;
    final chartHeight = size.height - 20;

    for (int i = 0; i < data.length; i++) {
      final value = data[i].totalDispensed;
      final barHeight =
      maxValue == 0 ? 0 : (value / maxValue) * chartHeight;

      final left = i * (barWidth + spacing);
      final top = chartHeight - barHeight;

      // BAR
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight.toDouble()),
          const Radius.circular(6),
        ),
        barPaint,
      );

      // VALUE TEXT
      textPainter.text = TextSpan(
        text: value.toString(),
        style: const TextStyle(fontSize: 10, color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, top - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StockChartPainter oldDelegate) =>
      oldDelegate.data != data;
}
