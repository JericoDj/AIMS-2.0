import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../controllers/barCodeController.dart';

class OfflineQrUtil {
  static Future<String> generateAndSaveQr({
    required String itemId,
  }) async {
    // Generate QR PNG (same logic as online)
    final Uint8List pngBytes =
    await BarcodeController.generateQrPng(itemId);

    final dir = await getApplicationDocumentsDirectory();
    final qrDir = Directory('${dir.path}/offline_qr');

    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }

    final file = File('${qrDir.path}/$itemId.png');
    await file.writeAsBytes(pngBytes);

    return file.path; // local file path
  }
}