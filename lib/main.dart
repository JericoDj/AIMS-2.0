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

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 MUST await this
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔥 Firebase apps: ${Firebase.apps}');


  final dir = await getApplicationDocumentsDirectory();
  final storageDir = Directory(dir.path);

  if (!await storageDir.exists()) {
    await storageDir.create(recursive: true);
  }

  await GetStorage.init();

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
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),

        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider.value(
          value: OfflineTransactionsProvider.instance,
        ),
        ChangeNotifierProvider(
          create: (_) => OfflineInventoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncRequestProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {

          const Color kPrimaryGreen = Color(0xFF2E7D32);
          const Color kLightGreen   = Color(0xFFD0E8B5);
          const Color kBorderGreen  = Color(0xFF43A047);
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

                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                ),

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
                  borderSide: const BorderSide(
                    color: kPrimaryGreen,
                    width: 2,
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              iconTheme: const IconThemeData(
                color: kPrimaryGreen,
              ),
            ),
            routerConfig: createRouter(accountsProvider),
          );
        },
      ),
    );
  }
}

