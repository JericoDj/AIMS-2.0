import 'package:aims2frontend/screens/landing/widgets/login_base_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/accounts_provider.dart';
import '../../utils/enums/role_enum.dart';
import '../../models/AccountModel.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountsProvider = context.read<AccountsProvider>();

    return LoginBasePage(
      title: "Admin Login",
      onLogin: (email, password) async {
        try {
          /// 1️⃣ Firebase Auth login
          final credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          final uid = credential.user!.uid;

          /// 2️⃣ Fetch user from Firestore
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (!snapshot.exists) {
            throw Exception("Account not found");
          }

          /// 3️⃣ Build Account from snapshot (WITH ID)
          final account = Account.fromMap({
            ...snapshot.data()!,
            'id': snapshot.id, // ✅ ensure correct ID
          });

          /// 4️⃣ Verify ADMIN role
          if (account.role != UserRole.admin) {
            throw Exception("Not authorized as admin");
          }

          /// 5️⃣ Save FULL session (Firestore-backed)
          accountsProvider.setCurrentUser(account);

          /// 6️⃣ Navigate AFTER success
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
        content: Text(message.replaceAll('Exception:', '').trim()),
      ),
    );
  }
}
