import 'dart:typed_data';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:image/image.dart' as img;

class BarcodeImageDecoder {
  static final FlutterBarcodeSdk _sdk = FlutterBarcodeSdk();
  static bool _initialized = false;

  /// Call once at app start
  static Future<void> init() async {
    print("initializing decode");
    if (_initialized) return;

    await _sdk.setBarcodeFormats(
      BarcodeFormat.QR_CODE |
      BarcodeFormat.CODE_128,
    );

    print("setting initialization true");

    _initialized = true;
  }

  /// Decode barcode text from PNG bytes
  static Future<String?> decodeFromPng(Uint8List pngBytes) async {
    print('🟢 decodeFromPng: START');
    print('PNG BYTES LENGTH: ${pngBytes.length}');

    // 1️⃣ Decode PNG → Image
    final image = img.decodeImage(pngBytes);
    if (image == null) {
      print('❌ Failed to decode PNG to image');
      return null;
    }

    print('✅ Image decoded');
    print('WIDTH : ${image.width}');
    print('HEIGHT: ${image.height}');

    // 2️⃣ Get RGBA bytes (image v4+)
    final Uint8List rgbaBytes = image.toUint8List();
    print('✅ RGBA BYTES LENGTH: ${rgbaBytes.length}');
    print('EXPECTED RGBA SIZE: ${image.width * image.height * 4}');

    // 3️⃣ Convert RGBA → ARGB
    print('🔄 Converting RGBA → ARGB...');
    final Uint8List argbBytes = Uint8List(rgbaBytes.length);

    for (int i = 0; i < rgbaBytes.length; i += 4) {
      final r = rgbaBytes[i];
      final g = rgbaBytes[i + 1];
      final b = rgbaBytes[i + 2];
      final a = rgbaBytes[i + 3];

      argbBytes[i]     = a;
      argbBytes[i + 1] = r;
      argbBytes[i + 2] = g;
      argbBytes[i + 3] = b;

      // Log first pixel only (avoid spam)
      if (i == 0) {
        print('FIRST PIXEL RGBA: [$r, $g, $b, $a]');
        print('FIRST PIXEL ARGB: [${argbBytes[i]}, ${argbBytes[i + 1]}, ${argbBytes[i + 2]}, ${argbBytes[i + 3]}]');
      }
    }

    print('✅ RGBA → ARGB conversion done');

    final int width = image.width;
    final int height = image.height;
    final int stride = width * 4;

    print('STRIDE: $stride');
    print('PIXEL FORMAT INDEX: ${ImagePixelFormat.IPF_ARGB_8888.index}');

    // 4️⃣ Decode using flutter_barcode_sdk
    print('🔍 Calling decodeImageBuffer...');
    final results = await _sdk.decodeImageBuffer(
      argbBytes,
      width,
      height,
      stride,
      ImagePixelFormat.IPF_ARGB_8888.index,
      0,
    );

    print('✅ decodeImageBuffer returned');
    print('RESULT COUNT: ${results.length}');

    if (results.isEmpty) {
      print('⚠️ No barcode detected');
      return null;
    }

    print('🎯 BARCODE TEXT: ${results.first.text}');
    return results.first.text;
  }

}
