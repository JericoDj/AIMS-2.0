import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import '../../models/AppNotification.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/enums/stock_filter_enum.dart';

import '../Offline/OfflineInventoryPage.dart';
import '../Offline/OfflineStockMonitoringPage.dart';
import '../Offline/OfflineTransactionsPage.dart';
import '../Offline/dialogs/uploadToOnlineDialog.dart';

import '../admin/DashboardPage.dart';
import '../admin/InventoryPage.dart';
import '../admin/SettingsPage.dart';
import '../admin/StockMonitoringPage.dart';
import '../admin/TransactionsPage.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, this.forceOffline});
  final bool? forceOffline;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  static const String _currentUserKey = 'current_user';

  int selectedIndex = 0;
  bool isOfflineMode = false;

  String? pendingSearchValue;
  StockFilter? pendingStockFilter;

  final GetStorage box = GetStorage();

  bool _hasValidOfflineUser() {
    final data = box.read(_currentUserKey);
    if (data == null || data is! Map) return false;

    return data['id'] != null &&
        data['email'] != null &&
        data['fullName'] != null;
  }

  @override
  void initState() {
    super.initState();

    if (widget.forceOffline == true) {
      isOfflineMode = true;
      selectedIndex = 0;
    }
  }

  // ---------------- USER MENUS ----------------
  final onlineMenu = [
    {"icon": Icons.dashboard, "label": "Dashboard"},
    {"icon": Icons.inventory, "label": "Inventory"},
    {"icon": Icons.monitor_heart, "label": "Stock Monitoring"},
    {"icon": Icons.swap_horiz, "label": "Transactions"},
    {"icon": Icons.settings, "label": "Settings"},
  ];

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
  // SIDEBAR
  // -----------------------------------
  Widget _buildSidebar(BuildContext context, List menuItems) {
    return Container(
      width: 260,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 20),

          // PROFILE
          Column(
            children: [
              if (!isOfflineMode)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.notifications, color: Colors.green[800]),
                    onPressed: _showNotificationPanel,
                  ),
                ),
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage("assets/Avatar2.jpeg"),
              ),
              const SizedBox(height: 10),
              Consumer<AccountsProvider>(
                builder: (_, acc, __) => Text(
                  acc.currentUser?.fullName ?? "User",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                isOfflineMode ? "(OFFLINE MODE)" : "User",
                style: TextStyle(
                  color: isOfflineMode ? Colors.red : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // MENU
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (_, index) {
                final item = menuItems[index];
                final selected = selectedIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: selected ? Colors.green : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          item["icon"] as IconData,
                          color:
                          selected ? Colors.white : Colors.green[800],
                        ),
                        const SizedBox(width: 15),
                        Text(
                          item["label"] as String,
                          style: TextStyle(
                            color:
                            selected ? Colors.white : Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // UPLOAD TO ONLINE (OFFLINE ONLY)
          if (isOfflineMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const UploadToOnlineDialog(),
                  );
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload to Online"),
              ),
            ),

          // ONLINE / OFFLINE TOGGLE
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () {
                if (widget.forceOffline == true) return;

                if (isOfflineMode) {
                  setState(() {
                    isOfflineMode = false;
                    selectedIndex = 0;
                  });
                  return;
                }

                if (!_hasValidOfflineUser()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text("Login online first to enable offline mode"),
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
                  color:
                  isOfflineMode ? Colors.red[300] : Colors.green[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    isOfflineMode ? "OFFLINE MODE" : "ONLINE MODE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LOGOUT
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: GestureDetector(
              onTap: () =>
                  context.read<AccountsProvider>().logout(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text("Logout", style: TextStyle(color: Colors.green[800])),
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
  Widget _buildRightPanel(List menuItems) {
    return Expanded(
      child: Column(
        children: [
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
                const Expanded(
                  child: Text(
                    "Provincial Government of Bulacan Pharmacy",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  // CONTENT SWITCHER
  // -----------------------------------
  Widget _buildContent() {
    if (!isOfflineMode) {
      switch (selectedIndex) {
        case 0:
          return DashboardPage(
            onStatTap: (f) {
              setState(() {
                selectedIndex = 2;
                pendingStockFilter = f;
              });
            },
            onChartItemTap: (name) {
              setState(() {
                selectedIndex = 3;
                pendingSearchValue = name.toLowerCase();
              });
            },
          );
        case 1:
          return const InventoryPage();
        case 2:
          return StockMonitoringPage(
            initialSearch: pendingSearchValue,
            initialFilter: pendingStockFilter,
          );
        case 3:
          return TransactionsPage(initialSearch: pendingSearchValue);
        case 4:
          return const SettingsPage();
      }
    } else {
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

  // -----------------------------------
  // NOTIFICATIONS
  // -----------------------------------
  void _showNotificationPanel() {
    // ✅ Fetch first batch (reset)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          alignment: Alignment.topLeft,
          insetPadding: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.025,
            left: MediaQuery.of(context).size.width * 0.12,
          ),
          child: Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.30,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER =================
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

                    const SizedBox(height: 12),

                    // ================= BODY =================
                    if (notifProvider.notifications.isEmpty && !notifProvider.loading)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text("No notifications available.")),
                      )
                    else
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55, // 🔑 scroll area
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // ================= LIST =================
                              ...notifProvider.notifications.map((n) {
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(
                                        n.read
                                            ? Icons.notifications_none
                                            : Icons.notifications_active,
                                        color: n.read ? Colors.grey : Colors.green,
                                      ),
                                      title: Text(
                                        n.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(n.message),
                                      trailing: Text(
                                        _formatTime(n.createdAt),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      onTap: () {
                                        context
                                            .read<NotificationProvider>()
                                            .markAsRead(n.id);

                                        Navigator.pop(context);
                                        _handleNotificationNavigation(n);
                                      },
                                    ),
                                    const Divider(height: 6),
                                  ],
                                );
                              }),

                              // ================= READ MORE =================
                              if (notifProvider.hasMore)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: TextButton(
                                    onPressed: notifProvider.loading
                                        ? null
                                        : () {
                                      context
                                          .read<NotificationProvider>()
                                          .fetchNotifications();
                                    },
                                    child: notifProvider.loading
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text(
                                      "Read more",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleNotificationNavigation(AppNotification n) {
    final type = n.type;
    final itemName = n.itemName;

    setState(() {
      pendingSearchValue = itemName;

      // INVENTORY-RELATED
      if (type == 'LOW_STOCK' ||
          type == 'NEAR_EXPIRY' ||
          type == 'OUT_OF_STOCK') {
        isOfflineMode = false;
        selectedIndex = 2; // Inventory Management
      }

      // TRANSACTION-RELATED
      else if (type == 'DISPENSE' || type == 'STOCK_ADDED') {
        isOfflineMode = false;
        selectedIndex = 3; // Transactions
      }
    });
  }


  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
