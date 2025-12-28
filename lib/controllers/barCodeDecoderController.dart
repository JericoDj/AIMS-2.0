import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

class DesktopBarcodeReader {
  /// Decode barcode / QR from raw image bytes (PNG/JPG)
  static String? decodeFromBytes(Uint8List bytes) {
    try {
      final Code result = zx.readBarcode(
        bytes,
        DecodeParams(
            format: Format.qrCode | Format.code128
        ),
      );

      if (!result.isValid) {
        return null;
      }

      return result.text;
    } catch (e) {
      // Non-fatal: decoding may fail if image has no barcode
      debugPrint('❌ Desktop barcode decode failed: $e');
      return null;
    }
  }
}
