import 'package:aims2frontend/providers/accounts_provider.dart';
import 'package:aims2frontend/providers/items_provider.dart';
import 'package:aims2frontend/providers/offline_inventory_provider.dart';
import 'package:aims2frontend/providers/offline_transaction_provider.dart';
import 'package:aims2frontend/providers/sync_provider.dart';
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
        ChangeNotifierProvider(
          create: (_) => OfflineTransactionsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OfflineInventoryProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // ✅ SAFE: provider exists here
          final accountsProvider = context.read<AccountsProvider>();

          return MaterialApp.router(
            title: "AIMS 2.0 App",
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme:
              ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            routerConfig: createRouter(accountsProvider),
          );
        },
      ),
    );
  }
}

