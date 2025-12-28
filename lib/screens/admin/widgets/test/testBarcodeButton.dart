import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../../../controllers/barCodeController.dart';

class TestBarcodeRoundTripButton extends StatelessWidget {
  final String barcodeValue;

  const TestBarcodeRoundTripButton({
    super.key,
    required this.barcodeValue,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Test Code128 Generate & Read'),
      onPressed: () async {
        try {
          debugPrint('==============================');
          debugPrint('📦 CODE128 ROUND-TRIP TEST');

          // 1️⃣ Barcode value (PLAIN ID)
          debugPrint('🏷 BARCODE VALUE: $barcodeValue');

          // 2️⃣ Generate Code128 PNG
          final barcodeResult =
          BarcodeController.generateCode128(barcodeValue);

          final Uint8List pngBytes = barcodeResult.pngBytes;
          debugPrint('🖼 PNG SIZE: ${pngBytes.length} bytes');

          // 3️⃣ Save PNG locally (Documents)
          final Directory dir =
          await getApplicationDocumentsDirectory();

          final File file =
          File('${dir.path}/test_code128.png');

          await file.writeAsBytes(pngBytes);

          debugPrint('💾 BARCODE SAVED AT:');
          debugPrint(file.path);

          // 4️⃣ Read PNG back
          final Uint8List loadedBytes =
          await file.readAsBytes();

          debugPrint(
              '📤 READ BACK PNG (${loadedBytes.length} bytes)');

          // 5️⃣ Decode Code128
          final Code result = zx.readBarcode(
            loadedBytes,
            DecodeParams(
              format: Format.code128,
              tryHarder: true,
              tryRotate: true,
              maxSize: 2048,
            ),
          );

          if (!result.isValid || result.text == null) {
            debugPrint('❌ NO BARCODE DETECTED');
            return;
          }

          debugPrint('📥 DECODED VALUE: ${result.text}');

          debugPrint(
            result.text == barcodeValue
                ? '✅ CODE128 ROUND-TRIP PASSED'
                : '❌ CODE128 VALUE MISMATCH',
          );

          debugPrint('==============================');
        } catch (e, s) {
          debugPrint('❌ TEST FAILED: $e');
          debugPrintStack(stackTrace: s);
        }
      },
    );
  }
}
