import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dialogs/create_account_dialog.dart';
import '../../models/AccountModel.dart';
import '../../providers/accounts_provider.dart';
class ManageAccountsPage extends StatelessWidget {
  const ManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountsProvider = context.watch<AccountsProvider>();
    final accounts = accountsProvider.accounts;
    final currentUser = accountsProvider.currentUser;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // ------------------- PROFILE GREETING -------------------
          if (currentUser != null)
            Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage(
                    // currentUser.image ??
                        'assets/Avatar2.jpeg',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Hi, ${currentUser.fullName}!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser.role.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 35),

          // ------------------- MAIN CARD -------------------
          Container(
            width: 700,
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8B5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              children: [
                // ------------------- USER ROWS -------------------
                if (accounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      "No accounts found",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                for (var index = 0; index < accounts.length; index++)
                  Column(
                    children: [
                      _UserRow(
                        image:
                        // accounts[index].image ??
                            'assets/Avatar2.jpeg',
                        name: accounts[index].fullName,
                        role: accounts[index].role.name.toUpperCase(),
                        // onEdit: () {
                        //   // TODO: Open edit dialog
                        // },
                        onRemove: () {
                          _confirmRemove(
                            context,
                            accountsProvider,
                            accounts[index],
                          );
                        },
                      ),

                      if (index != accounts.length - 1)
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.6),
                          margin:
                          const EdgeInsets.symmetric(horizontal: 20),
                        ),
                    ],
                  ),

                // ------------------- CREATE ACCOUNT -------------------
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateAccountDialog(),
                    );
                  },
                  child: Container(
                    height: 70,
                    alignment: Alignment.center,
                    child: Text(
                      "+ Create Account",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- REMOVE CONFIRMATION -------------------
  void _confirmRemove(
      BuildContext context,
      AccountsProvider provider,
      Account account,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        final passwordCtrl = TextEditingController();

        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Remove ${account.fullName}?",
              ),

              if (account.role.name.toLowerCase() == "admin") ...[
                const SizedBox(height: 12),
                const Text(
                  "Admin account requires password confirmation",
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Your password",
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (account.role.name.toLowerCase() == "admin") {
                    await provider.reauthenticateAdmin(passwordCtrl.text);
                  }

                  await provider.removeAccount(account.id,
                    adminPassword: passwordCtrl.text,
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}




//
// ==================== USER ROW WIDGET ====================
//
class _UserRow extends StatelessWidget {
  final String image;
  final String name;
  final String role;
  final VoidCallback? onRemove;

  const _UserRow({
    required this.image,
    required this.name,
    required this.role,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundImage: AssetImage(image)),
          const SizedBox(width: 20),

          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 20,
                color: Colors.green[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            role,
            style: TextStyle(
              fontSize: 18,
              color: Colors.green[900],
            ),
          ),

          const SizedBox(width: 40),

          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Text(
                "Remove",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

