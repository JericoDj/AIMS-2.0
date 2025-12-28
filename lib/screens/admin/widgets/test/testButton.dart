import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../../../controllers/barCodeController.dart';

class DecodeBarcodeButton extends StatelessWidget {
  final String assetPath;
  final String originalName;

  const DecodeBarcodeButton({
    super.key,
    required this.assetPath,
    required this.originalName,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Decode Barcode'),
      onPressed: () async {
        try {
          debugPrint('==============================');
          debugPrint('🔘 DecodeBarcodeButton PRESSED');
          debugPrint('📦 Asset path: $assetPath');

          // 1️⃣ Load asset
          debugPrint('➡️ Attempting to load asset...');
          final ByteData data = await rootBundle.load(assetPath);

          debugPrint('✅ Asset loaded successfully');
          debugPrint('📦 ByteData length: ${data.lengthInBytes}');

          // 2️⃣ Convert to Uint8List
          final Uint8List bytes = data.buffer.asUint8List();
          debugPrint('✅ Converted to Uint8List');
          debugPrint('📦 Uint8List length: ${bytes.length}');

          // 3️⃣ Decode barcode
          debugPrint('🔍 Starting ZXing decode...');
          final Code result = zx.readBarcode(
            bytes,
            DecodeParams(
              format: Format.code128,
              tryHarder: true,
              tryRotate: true,
              tryDownscale: false,
              maxSize: 2048,
            ),
          );

          debugPrint('✅ ZXing decode finished');
          debugPrint('📊 isValid: ${result.isValid}');
          debugPrint('📄 text: ${result.text}');

          if (!result.isValid || result.text == null) {
            debugPrint('⚠️ No barcode detected in asset');
            return;
          }

          // 4️⃣ Decrypt
          final String decoded = result.text!;
          debugPrint('📥 DECODED TEXT: $decoded');

          final String decrypted =
          BarcodeController.decrypt(decoded);

          debugPrint('🔓 DECRYPTED VALUE: $decrypted');

          // 5️⃣ Optional validation
          assert(
          decrypted ==
              BarcodeController.normalizeForKey(originalName),
          '❌ Barcode decrypt mismatch',
          );

          debugPrint('✅ Barcode validation PASSED');
          debugPrint('==============================');
        } catch (e, s) {
          debugPrint('❌ Decode failed');
          debugPrint('ERROR: $e');
          debugPrintStack(stackTrace: s);
        }
      },
    );
  }
}
