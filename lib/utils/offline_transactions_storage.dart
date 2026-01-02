import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/TransactionModel.dart';

class OfflineTransactionsStorage {
  static const _fileName = 'offline_transactions.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_fileName';
    debugPrint('📁 [TX FILE] $path');
    return File(path);
  }

  // ================= SAVE =================
  static Future<void> save(List<InventoryTransaction> list) async {
    final file = await _file();
    final json = const JsonEncoder.withIndent('  ')
        .convert(list.map((e) => e.toJson()).toList());

    await file.writeAsString(json);
    debugPrint('💾 [TX SAVE] ${list.length} transactions');
  }

  // ================= LOAD =================
  static Future<List<InventoryTransaction>> load() async {
    final file = await _file();

    if (!await file.exists()) {
      debugPrint('⚠️ [TX LOAD] No file');
      return [];
    }

    final raw = await file.readAsString();
    debugPrint('📦 [TX LOAD RAW]');
    debugPrint(raw);

    final decoded = jsonDecode(raw) as List;

    return decoded
        .map((e) =>
        InventoryTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
