import 'package:aims2frontend/screens/landing/widgets/login_base_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/accounts_provider.dart';
import '../../utils/enums/role_enum.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountsProvider = context.read<AccountsProvider>();

    return LoginBasePage(
      title: "Admin Login",
      onLogin: (email, password) async {
        try {
          print("working");
          /// ✅ 1. Login using Provider (single source of truth)
          await accountsProvider.loginWithEmail(
            email: email,
            password: password,
          );

          /// ✅ 2. Get logged-in user from provider
          final account = accountsProvider.currentUser;

          print(account);

          if (account == null) {
            throw Exception("Login failed");
          }

          /// ✅ 3. Verify ADMIN role
          if (account.role != UserRole.admin) {
            throw Exception("Not authorized as admin");
          }

          /// ✅ 4. Navigate AFTER success
          context.go('/admin');
        } catch (e) {
          _showError(context, e.toString());
        }
      },
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message.replaceAll('Exception:', '').trim(),
        ),
      ),
    );
  }
}
