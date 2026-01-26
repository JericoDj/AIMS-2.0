import 'package:aims2frontend/screens/landing/LandingPage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/accounts_provider.dart';
import 'Offline/OfflineBasePage.dart';
import 'admin/AdminLogin.dart';
import 'admin/AdminPage.dart';

import 'admin/SyncPage.dart';
import 'auth/forgot_password_page.dart';
import 'user/UserLoginPage.dart';
import 'user/UserPage.dart';
GoRouter createRouter(AccountsProvider accountsProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: accountsProvider,
    redirect: (context, state) {
      final isLoggedIn = accountsProvider.isLoggedIn;
      final isAdmin = accountsProvider.isAdmin;
      final isUser = accountsProvider.isUser;

      final location = state.uri.toString();

      // ================= OFFLINE (ALWAYS ALLOWED) =================
      if (location == '/offline') {
        return null;
      }

      // ================= NOT LOGGED IN =================
      if (!isLoggedIn) {
        if (location == '/login/admin' || location.startsWith('/login')) {
          return null;
        }
        return '/login/admin';
      }

      // ================= ADMIN =================
      if (isAdmin) {
        if (location.startsWith('/admin')) {
          return null;
        }
        return '/admin';
      }

      // ================= USER =================
      if (isUser) {
        if (location.startsWith('/user')) {
          return null;
        }
        return '/user';
      }

      return null;
    },

    routes: [
      // ---------------- LANDING ----------------
      GoRoute(
        path: '/',
        builder: (_, __) => const AdminLoginPage(),
      ),

      // ---------------- ADMIN ----------------
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminPage(),
      ),
      GoRoute(
        path: '/admin-offline',
        builder: (_, __) => const AdminPage(forceOffline: true),
      ),

      // ---------------- OFFLINE ----------------
      GoRoute(
        path: '/offline',
        builder: (_, __) => const OfflineModeBasePage(),
      ),

      // ---------------- USER ----------------
      GoRoute(
        path: '/user',
        builder: (_, __) => const UserPage(),
      ),

      // ---------------- AUTH ----------------
      GoRoute(
        path: '/login/admin',
        builder: (_, __) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/login/user',
        builder: (_, __) => const UserLoginPage(),
      ),

      // ---------------- SYNC ----------------
      GoRoute(
        path: '/admin/sync',
        builder: (_, __) => const SyncPage(),
      ),
    ],
  );
}


