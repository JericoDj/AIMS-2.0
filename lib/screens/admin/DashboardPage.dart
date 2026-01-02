import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
              const Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
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
                            const Text(
                              "Stock Overview",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 25),

                            Expanded(
                              child: CustomPaint(
                                painter: StockChartPainter(),
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

                  return Container(
                    height: cardHeight  ,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        DashboardStatCard(
                          title: "Low Stock",
                          value: "18",
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                          width: cardWidth,
                          height: cardHeight,
                        ),
                        DashboardStatCard(
                          title: "Out of Stock",
                          value: "5",
                          icon: Icons.error_outline,
                          iconColor: Colors.red,
                          width: cardWidth,
                          height: cardHeight,
                        ),
                        DashboardStatCard(
                          title: "Expiring Soon",
                          value: "9",
                          icon: Icons.timer_outlined,
                          iconColor: Colors.orange,
                          width: cardWidth,
                          height: cardHeight,
                        ),
                      ],
                    ),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: height * 0.20, color: iconColor ?? Colors.green[800]),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: height * 0.15,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: height * 0.12,
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
  @override
  void paint(Canvas canvas, Size size) {
    final barColor = Paint()..color = Colors.green[800]!;
    double barWidth = size.width * 0.15;
    double spacing = size.width * 0.07;

    List<double> values = [80, 60, 40, 100, 70];

    for (int i = 0; i < values.length; i++) {
      double left = i * (barWidth + spacing);
      double top = size.height - (values[i] * 0.8);

      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth, values[i] * 0.8),
        barColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
