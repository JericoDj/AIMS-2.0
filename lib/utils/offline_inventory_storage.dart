import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ItemModel.dart';

class OfflineInventoryStorage {
  static const _fileName = 'offline_items.json';

  static Future<File> _file() async {
    final baseDir = await getApplicationSupportDirectory();

    final dataDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}offline_data',
    );

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    return File(
      '${dataDir.path}${Platform.pathSeparator}$_fileName',
    );
  }


  // ================= SAVE =================
  // ================= SAVE =================
  static Future<void> save(List<ItemModel> items) async {
    final file = await _file();

    final jsonData = items.map((e) => e.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    await file.writeAsString(jsonString);

    debugPrint('💾 [OFFLINE SAVE]');
    debugPrint('Items saved: ${items.length}');
    debugPrint(jsonString);
  }

  // ================= LOAD =================
  static Future<List<ItemModel>> load() async {
    final file = await _file();

    if (!await file.exists()) {
      debugPrint('⚠️ [OFFLINE LOAD] File does not exist');
      return [];
    }

    final raw = await file.readAsString();

    debugPrint('📦 [OFFLINE LOAD RAW]');
    debugPrint(raw);

    final decoded = jsonDecode(raw) as List;

    return decoded
        .map((e) => ItemModel.fromJson(e))
        .toList();
  }

  // ================= CLEAR =================
  static Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ [OFFLINE CLEAR] File deleted');
    }
  }
}
