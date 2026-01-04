import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SettingsButton(
                label: "User\nGuide",
                onTap: () => _showUserGuideDialog(context),
              ),

              const SizedBox(width: 60),

              SettingsButton(
                label: "System\nVersion Info.",
                onTap: () => _showVersionDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= USER GUIDE =================
  void _showUserGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.5,
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            children: [
              _dialogHeader(context, "User Guide"),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: const [
                      _GuideSection(
                        image: Icons.dashboard,
                        title: "Dashboard",
                        description:
                        "Provides an overview of the current month's activity, "
                            "including low stock items, out-of-stock items, "
                            "and nearly-expiry medicines.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.inventory_2,
                        title: "Inventory Management",
                        description:
                        "View all available stocks, add new stock entries, "
                            "and dispense items. Inventory is tracked accurately "
                            "based on quantity and expiry.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.monitor_heart,
                        title: "Stock Monitoring",
                        description:
                        "Add new items, generate inventory reports, search "
                            "specific medicines, download QR codes, and set "
                            "low stock thresholds for alerts.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.swap_horiz,
                        title: "Transactions",
                        description:
                        "View all inventory transactions, generate transaction "
                            "reports, inspect transaction details, and delete records "
                            "when necessary.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.manage_accounts,
                        title: "Manage Accounts",
                        description:
                        "View user access levels, create new accounts, "
                            "and remove existing user accounts.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.sync,
                        title: "Sync Requests",
                        description:
                        "Review offline sync requests, validate operations, "
                            "and synchronize offline data with the online system.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.cloud_off,
                        title: "Offline Mode",
                        description:
                        "Allows creation of inventory data and transactions "
                            "even without an internet connection. Data is stored "
                            "locally until synced.",
                      ),

                      SizedBox(height: 24),

                      _GuideSection(
                        image: Icons.cloud_upload,
                        title: "Upload to Online",
                        description:
                        "Request synchronization of offline data to the "
                            "online database. Once completed, offline records "
                            "are safely cleared.",
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ================= VERSION INFO =================
  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader(context, "System Version"),

              const Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        size: 60, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      "Version 2.0.1",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Provincial Government of Bulacan Pharmacy System",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= COMMON HEADER =================
  Widget _dialogHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final IconData image;
  final String title;
  final String description;

  const _GuideSection({
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(image, size: 48, color: Colors.green),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
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
          border: Border.all(
            width: 3,
            color: Colors.green[600]!,
          ),
          color: Colors.green[50], // soft green
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
