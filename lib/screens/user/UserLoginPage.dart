import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/accounts_provider.dart';
import '../../models/AccountModel.dart';
import '../../utils/enums/role_enum.dart';
import '../landing/widgets/login_base_page.dart';

class UserLoginPage extends StatelessWidget {
  const UserLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountsProvider = context.read<AccountsProvider>();

    return LoginBasePage(
      title: "User Login",
      onLogin: (email, password) async {
        try {
          /// 1️⃣ Firebase Auth login
          final credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          final uid = credential.user!.uid;

          /// 2️⃣ Fetch user data
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (!snapshot.exists) {
            throw Exception("Account not found");
          }

          final account =
          Account.fromMap(snapshot.data() as Map<String, dynamic>);

          /// 3️⃣ Verify USER role
          if (account.role != UserRole.user) {
            throw Exception("Not authorized as user");
          }

          /// 4️⃣ Save session
          await accountsProvider.loginWithEmail(
            email: email,
            password: password,
          );

          /// 5️⃣ Navigate AFTER success
          context.go('/user');
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
