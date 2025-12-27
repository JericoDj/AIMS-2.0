import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:barcode/barcode.dart';
import 'package:barcode_image/barcode_image.dart';
import 'package:image/image.dart' as img;
class BarcodeController {
  static final Key _key =
  Key.fromUtf8('AIMSINVENTORYBARCODEKEY012345678');

  static final Encrypter _encrypter =
  Encrypter(AES(_key, mode: AESMode.cbc));

  static String normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String generate(String itemName) {
    final iv = IV.fromSecureRandom(16);
    print('IV(base64): ${iv.base64}');
    print('INPUT: ${normalize(itemName)}');

    try {
      print('KEY BYTES: ${_key.bytes.length}');
      print('IV BYTES: ${iv.bytes.length}');

      final encrypted =
      _encrypter.encrypt(normalize(itemName), iv: iv);

      print('ENC(base64): ${encrypted.base64}');
      return '${iv.base64}:${encrypted.base64}';
    } catch (e, s) {
      print('❌ FAILED AT ENCRYPT');
      print(e);
      print(s);
      rethrow;
    }
  }

  static String decrypt(String payload) {
    final parts = payload.split(':');
    return _encrypter.decrypt(
      Encrypted.fromBase64(parts[1]),
      iv: IV.fromBase64(parts[0]),
    );
  }


  /// Barcode image
  static Uint8List generateBarcodePng(String barcodeValue, {
    int width = 800,
    int height = 200,
  }) {
    final barcode = Barcode.code128();
    final image = img.Image(width: width, height: height);

    // ✅ Fill background with white
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // ✅ Draw barcode (black bars on white background)
    drawBarcode(
      image,
      barcode,
      barcodeValue,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodePng(image));
  }


}
