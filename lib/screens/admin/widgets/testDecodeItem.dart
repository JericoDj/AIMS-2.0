import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../../controllers/barCodeController.dart';

class DecodeAssetBarcodeButton extends StatelessWidget {
  final String assetPath;

  const DecodeAssetBarcodeButton({
    super.key,
    this.assetPath = 'assets/test_barcode.png',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Decode Asset Barcode'),
      onPressed: () async {
        try {
          debugPrint('==============================');
          debugPrint('📦 DECODE BARCODE FROM ASSET');
          debugPrint('📁 Asset path: $assetPath');

          // ✅ 1️⃣ LOAD ASSET BYTES (correct)
          final ByteData data = await rootBundle.load(assetPath);
          final Uint8List bytes = data.buffer.asUint8List();

          debugPrint('✅ Asset loaded');
          debugPrint('🖼 Byte size: ${bytes.length}');

          // ✅ 2️⃣ DECODE USING BYTES (NOT path)
          final Code result = zx.readBarcode(
            bytes,
            DecodeParams(
              format: Format.code128,
              tryHarder: true,
              tryRotate: true,
              maxSize: 2048,
            ),
          );

          debugPrint('📊 isValid: ${result.isValid}');
          debugPrint('📄 text: ${result.text}');

          if (!result.isValid || result.text == null) {
            debugPrint('❌ NO BARCODE DETECTED');
            return;
          }

          debugPrint('📥 DECODED BARCODE VALUE:');
          debugPrint(result.text!);

          // 🔐 OPTIONAL: decrypt
          try {
            final String decrypted =
            BarcodeController.decrypt(result.text!);
            debugPrint('🔓 DECRYPTED VALUE:');
            debugPrint(decrypted);
          } catch (_) {
            debugPrint('ℹ️ Value is not encrypted');
          }

          debugPrint('==============================');
        } catch (e, s) {
          debugPrint('❌ DECODE FAILED: $e');
          debugPrintStack(stackTrace: s);
        }
      },
    );
  }
}
