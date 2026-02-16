import 'package:aims2frontend/providers/accounts_provider.dart';
import 'package:aims2frontend/providers/items_provider.dart';
import 'package:aims2frontend/providers/notification_provider.dart';
import 'package:aims2frontend/providers/offline_inventory_provider.dart';
import 'package:aims2frontend/providers/offline_transaction_provider.dart';
import 'package:aims2frontend/providers/sync_provider.dart';
import 'package:aims2frontend/providers/sync_request_provider.dart';
import 'package:aims2frontend/providers/transactions_provider.dart';
import 'package:aims2frontend/screens/router.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔐 INIT WINDOW MANAGER
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: Size(1024, 768),
      center: true,
      // titleBarStyle: TitleBarStyle.hidden, // optional but recommended
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();

      // 🔥 FORCE TRUE FULLSCREEN
      await windowManager.maximize();
    },
  );

  // Windows-safe directory
  final supportDir = await getApplicationSupportDirectory();
  if (!await supportDir.exists()) {
    await supportDir.create(recursive: true);
  }

  // =====================================================
  // GETSTORAGE INITIALIZATION (CORRECT & ORDERED)
  // =====================================================

  // 1️⃣ Initialize default container (required internally)
  await GetStorage.init();

  // 2️⃣ Create your named container WITH PATH
  final currentUserBox = GetStorage('current_user', supportDir.path);

  // 3️⃣ Force init (important on Windows)
  await currentUserBox.initStorage;

  // =====================================================
  // 🔍 DEBUG: READ STORED USER BEFORE APP STARTS
  // =====================================================
  final storedUser = currentUserBox.read('current_user');

  debugPrint('🔎 [BOOT] Stored current_user:');
  if (storedUser == null) {
    debugPrint('❌ No user found in storage');
  } else {
    debugPrint('✅ User FOUND in storage');
    debugPrint(storedUser.toString());
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),

        ChangeNotifierProxyProvider<AccountsProvider, TransactionsProvider>(
          create:
              (context) =>
                  TransactionsProvider(context.read<AccountsProvider>()),
          update: (context, accountsProvider, previous) {
            previous?.updateAccountsProvider(accountsProvider);
            return previous ?? TransactionsProvider(accountsProvider);
          },
        ),

        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider.value(
          value: OfflineTransactionsProvider.instance,
        ),
        ChangeNotifierProvider(create: (_) => OfflineInventoryProvider()),
        ChangeNotifierProxyProvider<AccountsProvider, SyncRequestProvider>(
          create:
              (context) =>
                  SyncRequestProvider(context.read<AccountsProvider>()),
          update:
              (context, accounts, previous) =>
                  previous ?? SyncRequestProvider(accounts),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Builder(
        builder: (context) {
          const Color kPrimaryGreen = Color(0xFF2E7D32);
          const Color kLightGreen = Color(0xFFD0E8B5);
          const Color kBorderGreen = Color(0xFF43A047);
          // ✅ SAFE: provider exists here
          final accountsProvider = context.read<AccountsProvider>();

          return MaterialApp.router(
            title: "AIMS 2.0 App",
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,

              // ================= COLOR SCHEME =================
              colorScheme: ColorScheme.light(
                primary: kPrimaryGreen,
                secondary: kBorderGreen,
                surface: Colors.white,
                background: Colors.white,
                error: Colors.red,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: Colors.black87,
                onBackground: Colors.black87,
              ),

              scaffoldBackgroundColor: Colors.white,

              // ================= APP BAR =================
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: kPrimaryGreen,
                elevation: 0,
                centerTitle: false,
                titleTextStyle: TextStyle(
                  color: kPrimaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // ================= INPUTS (TextField, Dropdown, Date) =================
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),

                labelStyle: const TextStyle(
                  color: kPrimaryGreen,
                  fontWeight: FontWeight.w500,
                ),

                hintStyle: TextStyle(color: Colors.grey.shade600),

                prefixIconColor: kPrimaryGreen,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorderGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorderGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),

              // ================= BUTTONS =================
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryGreen,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // ================= DROPDOWN =================
              dropdownMenuTheme: DropdownMenuThemeData(
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorderGreen),
                  ),
                ),
              ),

              // ================= DIALOG =================

              // ================= DATE PICKER =================
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.white,

                // HEADER
                headerBackgroundColor: kPrimaryGreen,
                headerForegroundColor: Colors.white,

                // TODAY
                todayBackgroundColor: MaterialStateProperty.all(kLightGreen),
                todayForegroundColor: MaterialStateProperty.all(kPrimaryGreen),

                // ✅ SELECTED DAY (THIS IS WHAT YOU WANT)
                dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return kPrimaryGreen; // circle background
                  }
                  return null;
                }),
                dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white; // text color
                  }
                  return Colors.black87;
                }),

                // SHAPE
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // ================= CHIP =================
              chipTheme: ChipThemeData(
                backgroundColor: kLightGreen,
                labelStyle: const TextStyle(color: kPrimaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // ================= ICON =================
              iconTheme: const IconThemeData(color: kPrimaryGreen),
            ),
            routerConfig: createRouter(accountsProvider),
          );
        },
      ),
    );
  }
}
