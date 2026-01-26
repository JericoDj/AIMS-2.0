import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../controllers/barCodeController.dart';

class OfflineQrUtil {
  /// Generates QR using the SAME payload as ONLINE (item name)
  static Future<String> generateAndSaveQr({
    required String payload, // ✅ item name
  }) async {
    // ✅ QR CONTENT = ITEM NAME (PLAIN TEXT)
    final Uint8List pngBytes =
    await BarcodeController.generateQrPng(payload);

    // ✅ SAME BASE DIR AS JSON
    final baseDir = await getApplicationSupportDirectory();
    final qrDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}offline_data',
    );

    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }

    // 🔒 filename can be normalized payload (safe)
    final safeName = payload
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_');

    final file = File(
      '${qrDir.path}${Platform.pathSeparator}$safeName.png',
    );

    await file.writeAsBytes(pngBytes, flush: true);

    return file.path; // ✅ absolute, stable path
  }
}
