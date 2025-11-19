import 'package:aims2frontend/screens/LandingPage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'AdminPage.dart';
import 'LoginPage.dart';
import 'UserPage.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'user';
        return LoginPage(type: type);
      },
    ),
    GoRoute(
      path: '/user',
      builder: (context, state) => const UserPage(),
    ),

  ],
);
