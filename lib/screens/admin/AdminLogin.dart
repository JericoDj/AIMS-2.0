import 'package:aims2frontend/screens/landing/widgets/login_base_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/AccountModel.dart';
import '../../providers/accounts_provider.dart';
import '../../utils/enums/role_enum.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {

  bool _obscurePassword = true;
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

          /// 2️⃣ Fetch admin data
          final snapshot = await FirebaseFirestore.instance
              .collection('users') // or 'admins' if you use a separate collection
              .doc(uid)
              .get();

          if (!snapshot.exists) {
            throw Exception("Account does not exist");
          }

          final account =
          Account.fromMap(snapshot.data() as Map<String, dynamic>);

          /// 3️⃣ Verify ADMIN role
          if (account.role != UserRole.admin) {
            throw Exception("You are not authorized as an admin");
          }

          /// 4️⃣ Save session (provider)
          await accountsProvider.loginWithEmail(
            email: email,
            password: password,
          );

          /// 5️⃣ Navigate AFTER success
          context.go('/admin');
        }

        // 🔐 AUTH-SPECIFIC ERRORS
        on FirebaseAuthException catch (e) {
          switch (e.code) {
            case 'user-not-found':
              _showError(context, 'Account does not exist');
              break;

            case 'wrong-password':
              _showError(context, 'Wrong password');
              break;

            case 'invalid-email':
              _showError(context, 'Invalid email address');
              break;

            case 'user-disabled':
              _showError(context, 'This account has been disabled');
              break;

            case 'too-many-requests':
              _showError(context, 'Too many attempts. Try again later.');
              break;

            default:
              _showError(context, 'Login failed. Please try again.');
          }
        }

        // ❗ ROLE / LOGIC ERRORS
        catch (e) {
          _showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
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
