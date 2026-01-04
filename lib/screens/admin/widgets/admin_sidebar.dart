import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/accounts_provider.dart';
import '../admin_state.dart';

class AdminSidebar extends StatelessWidget {
  final AdminState state;
  final ValueChanged<int> onMenuSelect;

  const AdminSidebar({
    super.key,
    required this.state,
    required this.onMenuSelect,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = state.menuItems;

    return Container(
      width: 260,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 20),

          /// PROFILE
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage("assets/JericoDeJesus.png"),
          ),
          const SizedBox(height: 10),
          const Text(
            "De Jesus, Jerico",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            state.isOfflineMode ? "(OFFLINE MODE)" : "Administrator",
            style: TextStyle(
              color: state.isOfflineMode ? Colors.red : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          /// MENU
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (_, i) {
                final item = menuItems[i];
                final selected = state.selectedIndex == i;

                return GestureDetector(
                  onTap: () => onMenuSelect(i),
                  child: Container(
                    height: 48,
                    color: selected ? Colors.lightGreen[300] : null,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          item["icon"],
                          color:
                          selected ? Colors.white : Colors.green[800],
                        ),
                        const SizedBox(width: 15),
                        Text(
                          item["label"],
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

          /// OFFLINE TOGGLE
          GestureDetector(
            onTap: () {
              try {
                state.toggleOfflineMode();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceAll('Exception:', '').trim(),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: state.forceOffline
                    ? Colors.grey
                    : state.isOfflineMode
                    ? Colors.red[300]
                    : Colors.green[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  state.forceOffline
                      ? "OFFLINE MODE (LOCKED)"
                      : state.isOfflineMode
                      ? "OFFLINE MODE"
                      : "ONLINE MODE",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// LOGOUT (PROVIDER-AWARE)
          GestureDetector(
            onTap: () {
              // 1️⃣ Clear auth/session
              context.read<AccountsProvider>().logout();

              // 2️⃣ Navigate to landing
              context.go('/');
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
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
}
