import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/accounts_provider.dart';
import '../Offline/OfflineInventoryPage.dart';
import '../Offline/OfflineStockMonitoringPage.dart';
import '../Offline/OfflineTransactionsPage.dart';
import '../admin/SettingsPage.dart';


class OfflineModeBasePage extends StatefulWidget {
  const OfflineModeBasePage({super.key});

  @override
  State<OfflineModeBasePage> createState() => _OfflineModeBasePageState();
}

class _OfflineModeBasePageState extends State<OfflineModeBasePage> {
  int selectedIndex = 0;

  // 🔒 OFFLINE ONLY MENU
  final offlineMenu = const [
    {"icon": Icons.inventory_2, "label": "Offline Inventory"},
    {"icon": Icons.monitor_heart, "label": "Offline Stock Monitoring"},
    {"icon": Icons.swap_horiz, "label": "Offline Transactions"},
    {"icon": Icons.settings, "label": "Settings"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildSidebar(context),
          _buildRightPanel(),
        ],
      ),
    );
  }

  // -----------------------------------
  // LEFT SIDEBAR (OFFLINE ONLY)
  // -----------------------------------
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 20),

          // PROFILE (NO NOTIFICATIONS)
          Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage("assets/Avatar2.jpeg"),
              ),
              const SizedBox(height: 10),
              Consumer<AccountsProvider>(
                builder: (context, accounts, _) {
                  final user = accounts.currentUser;
                  return Text(
                    user?.fullName ?? "Offline User",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  );
                },
              ),
              const Text(
                "(OFFLINE MODE)",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ------------------- MENU -------------------
          Expanded(
            child: ListView.builder(
              itemCount: offlineMenu.length,
              itemBuilder: (context, index) {
                final item = offlineMenu[index];
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    height: 48,
                    color: isSelected ? Colors.green : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          item["icon"] as IconData,
                          color: isSelected
                              ? Colors.white
                              : Colors.green[800],
                        ),
                        const SizedBox(width: 15),
                        Text(
                          item["label"] as String,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.green[900],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ------------------- LOGOUT -------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: GestureDetector(
              onTap: () {
               context.go('/landing');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text(
                    "Logout",
                    style: TextStyle(color: Colors.green[800]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------
  // RIGHT PANEL
  // -----------------------------------
  Widget _buildRightPanel() {
    return Expanded(
      child: Column(
        children: [
          // TOP BAR (NO TOGGLES / NOTIFS)
          Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Image.asset("assets/8xLogo.png", height: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Provincial Government of Bulacan Pharmacy",
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PAGE CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------
  // CONTENT SWITCHER (OFFLINE ONLY)
  // -----------------------------------
  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return const OfflineInventoryPage();
      case 1:
        return const OfflineStockMonitoringPage();
      case 2:
        return const OfflineTransactionsPage();
      case 3:
        return const SettingsPage();
      default:
        return const Center(child: Text("Unknown Page"));
    }
  }
}
