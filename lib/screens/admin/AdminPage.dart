import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// IMPORT ALL SUBPAGES
import '../../providers/accounts_provider.dart';
import '../../providers/sync_provider.dart';
import '../Offline/OfflineInventoryPage.dart';
import '../Offline/OfflineStockMonitoringPage.dart';
import '../Offline/OfflineTransactionsPage.dart';
import 'DashboardPage.dart';
import 'InventoryPage.dart';
import 'ManageAccountPage.dart';

import 'SettingsPage.dart';
import 'StockMonitoringPage.dart';
import 'TransactionsPage.dart';

// OFFLINE PAGES


class AdminPage extends StatefulWidget {
  const AdminPage({super.key, this.forceOffline});
  final bool? forceOffline;






  @override
  State<AdminPage> createState() => _AdminPageState();

}


class _AdminPageState extends State<AdminPage> {

  static const String _currentUserKey = 'current_user';
  int selectedIndex = 0;
  bool isOfflineMode = false;


  int notificationCount = 4; // example for now


  final GetStorage box = GetStorage();

  bool _hasValidOfflineUser() {


    final data = box.read(_currentUserKey);

    if (data == null) return false;
    if (data is! Map) return false;

    return data['id'] != null &&
        data['email'] != null &&
        data['fullName'] != null &&
        data['role'] != null;
  }



  List<Map<String, dynamic>> notifications = [
    {
      "title": "Low Stock Alert",
      "message": "Amoxicillin 500mg is below minimum threshold.",
      "time": "10:45 AM",
    },
    {
      "title": "New Transaction",
      "message": "A new transaction has been recorded.",
      "time": "9:20 AM",
    },
    {
      "title": "Sync Completed",
      "message": "Offline data synced successfully.",
      "time": "Yesterday",
    },
  ];
  void _showNotificationPanel() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.only(
            top: MediaQuery.sizeOf(context).width * 0.025,
            left: MediaQuery.sizeOf(context).width * 0.12,
          ),
          alignment: Alignment.topLeft,
          child: Container(
            width: MediaQuery.sizeOf(context).width * .30,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ------------------ HEADER WITH CLOSE BUTTON ------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // ------------------ EMPTY OR LIST ------------------
                if (notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No notifications available."),
                  )
                else
                  ...notifications.map((n) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications_active, color: Colors.green),
                          title: Text(
                            n["title"],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(n["message"]),
                          trailing: Text(
                            n["time"],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const Divider(height: 5),
                      ],
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.forceOffline == true) {
      isOfflineMode = true;
      selectedIndex = 0;
    }
  }


  // ------------------- ONLINE MENU -------------------
  final onlineMenu = [
    {"icon": Icons.dashboard, "label": "Dashboard"},
    {"icon": Icons.inventory, "label": "Inventory Management"},
    {"icon": Icons.monitor_heart, "label": "Stock Monitoring"},
    {"icon": Icons.swap_horiz, "label": "Transactions"},

    {"icon": Icons.manage_accounts, "label": "Manage Accounts"},
    {"icon": Icons.settings, "label": "Settings"},
  ];

  // ------------------- OFFLINE MENU -------------------
  final offlineMenu = [
    {"icon": Icons.inventory_2, "label": "Offline Inventory"},
    {"icon": Icons.monitor_heart, "label": "Offline Stock Monitoring"},
    {"icon": Icons.swap_horiz, "label": "Offline Transactions"},
    {"icon": Icons.settings, "label": "Settings"},
  ];

  @override
  Widget build(BuildContext context) {
    final menuItems = isOfflineMode ? offlineMenu : onlineMenu;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildSidebar(context, menuItems),
          _buildRightPanel(menuItems),
        ],
      ),
    );
  }

  // -----------------------------------
  // LEFT SIDEBAR
  // -----------------------------------
  Widget _buildSidebar(BuildContext context, List menuItems) {

    final isAdmin = context.watch<AccountsProvider>().isAdmin;
    final syncProvider = context.watch<SyncProvider>();
    return Container(
      width: 260,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 20),

          // PROFILE
          Column(
            children: [
              Column(
                children: [

                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: GestureDetector(
                        onTap: _showNotificationPanel,
                        child: Stack(
                          children: [
                            Icon(Icons.notifications, size: 30, color: Colors.green[800]),
                            if (notificationCount > 0)
                              Positioned(
                                right: 0,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    notificationCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage("assets/JericoDeJesus.png"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("De Jesus, Jerico",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                isOfflineMode ? "(OFFLINE MODE)" : "Administrator",
                style: TextStyle(
                  color: isOfflineMode ? Colors.red : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ------------------- MENU -------------------
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    height: 48,
                    color: isSelected
                        ? Colors.lightGreen[300]
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(item["icon"] as IconData,
                            color: isSelected
                                ? Colors.white
                                : Colors.green[800]),
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

          // ------------------- UPLOAD TO ONLINE (OFFLINE ONLY) -------------------
          if (isOfflineMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: your upload logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Uploading offline data to online..."),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                label: const Text(
                  "Upload to Online",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  minimumSize: const Size(200, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          if (isAdmin && !isOfflineMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/admin/sync');
                },
                icon: const Icon(Icons.sync),
                label: Text(
                  syncProvider.syncing ? "Syncing..." : "Sync Requests",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  minimumSize: const Size(200, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          // ------------------- ONLINE / OFFLINE MODE TOGGLE -------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () {
                // 🔒 Forced offline → locked
                if (widget.forceOffline == true) return;

                // 🧠 Going ONLINE → always allowed
                if (isOfflineMode) {
                  setState(() {
                    isOfflineMode = false;
                    selectedIndex = 0;
                  });
                  return;
                }

                // 🔍 Going OFFLINE → must have cached user
                final hasOfflineUser = _hasValidOfflineUser();

                if (!hasOfflineUser) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("No offline user found. Please login online first."),
                    ),
                  );
                  return;
                }

                setState(() {
                  isOfflineMode = true;
                  selectedIndex = 0;
                });
              },




              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: widget.forceOffline == true
                      ? Colors.grey
                      : isOfflineMode
                      ? Colors.red[300]
                      : Colors.green[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.forceOffline == true
                        ? "OFFLINE MODE (LOCKED)"
                        : isOfflineMode
                        ? "OFFLINE MODE"
                        : "ONLINE MODE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),


          // ------------------- LOGOUT -------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: GestureDetector(
              onTap: () {
                context.read<AccountsProvider>().logout();
                // ❌ NO context.go()
                // ✅ Router will redirect automatically
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
  // RIGHT PANEL + TOP BAR & NOTIFICATION
  // -----------------------------------
  Widget _buildRightPanel(List menuItems) {
    return Expanded(
      child: Column(
        children: [
          // TOP BAR
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
                  child: const Text(
                    "Provincial Government of Bulacan Pharmacy",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                ),

                // ------------------- NOTIFICATION ICON -------------------


                const SizedBox(width: 20),

                // ------------------- ONLINE/OFFLINE TOGGLE ------------------
                const SizedBox(width: 20),
              ],
            ),
          ),

          // PAGE CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildContent(menuItems),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------
  // CONTENT SWITCHER
  // -----------------------------------
  Widget _buildContent(List menuItems) {
    if (!isOfflineMode) {
      // ONLINE MODE
      switch (selectedIndex) {
        case 0:
          return const DashboardPage();
        case 1:
          return const InventoryPage();
        case 2:
          return const StockMonitoringPage();
        case 3:
          return const TransactionsPage();
        case 4:
          return const ManageAccountsPage();
        case 5:
          return const SettingsPage();
      }
    } else {
      // OFFLINE MODE
      switch (selectedIndex) {
        case 0:
          return const OfflineInventoryPage();
        case 1:
          return const OfflineStockMonitoringPage();
        case 2:
          return const OfflineTransactionsPage();
        case 3:
          return const SettingsPage();
      }
    }

    return const Center(child: Text("Unknown Page"));
  }
}
