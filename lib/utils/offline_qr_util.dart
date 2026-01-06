import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../controllers/barCodeController.dart';

class OfflineQrUtil {
  static Future<String> generateAndSaveQr({
    required String itemId,
  }) async {
    final Uint8List pngBytes =
    await BarcodeController.generateQrPng(itemId);

    // ✅ SAME BASE DIR AS JSON
    final baseDir = await getApplicationSupportDirectory();
    final qrDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}offline_data',
    );

    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }

    final file =
    File('${qrDir.path}${Platform.pathSeparator}$itemId.png');

    await file.writeAsBytes(pngBytes, flush: true);

    return file.path; // ✅ absolute, stable path
  }
}
