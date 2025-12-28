import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../../../controllers/barCodeController.dart';

class TestBarcodeToDesktopButton extends StatelessWidget {
  final String input;

  const TestBarcodeToDesktopButton({
    super.key,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Generate Barcode to Desktop'),
      onPressed: () async {
        try {
          debugPrint('==============================');
          debugPrint('🖥 DESKTOP BARCODE TEST');


          // 2️⃣ Barcode value (SHORT reference)
          final String barcodeValue = 'TEST-ITEM-001';

          // 3️⃣ Generate barcode PNG
          final barcode =
          BarcodeController.generateCode128(barcodeValue);

          final Uint8List pngBytes = barcode.pngBytes;

          // 4️⃣ Resolve Desktop path (cross-platform)
          final String home =
              Platform.environment['HOME'] ??
                  Platform.environment['USERPROFILE']!;

          final String desktopPath = '$home/Desktop';
          final File file =
          File('$desktopPath/test_barcode.png');

          await file.writeAsBytes(pngBytes);

          debugPrint('💾 SAVED TO DESKTOP: ${file.path}');

          // 5️⃣ Decode back
          final Code result = zx.readBarcode(
            pngBytes,
            DecodeParams(
              format: Format.code128,
              tryHarder: true,
            ),
          );

          if (!result.isValid || result.text == null) {
            debugPrint('❌ FAILED TO DECODE BARCODE');
            return;
          }

          debugPrint('📥 DECODED VALUE: ${result.text}');
          debugPrint(
            result.text == barcodeValue
                ? '✅ BARCODE ROUND-TRIP PASSED'
                : '❌ BARCODE MISMATCH',
          );

          debugPrint('==============================');
        } catch (e, s) {
          debugPrint('❌ ERROR: $e');
          debugPrintStack(stackTrace: s);
        }
      },
    );
  }
}
