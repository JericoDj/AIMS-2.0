import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:barcode/barcode.dart';
import 'package:barcode_image/barcode_image.dart';
import 'package:image/image.dart' as img;

class BarcodeController {
  // ================= SECURITY CONFIG =================
  static final Key _key =
  Key.fromUtf8('AIMS-INVENTORY-BARCODE-KEY-32');

  static final IV _iv =
  IV.fromUtf8('AIMS-INVENTORY-IV'); // 16 chars

  static final Encrypter _encrypter =
  Encrypter(AES(_key, mode: AESMode.cbc));

  // ================= NORMALIZATION =================
  static String normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  // ================= ENCRYPT =================
  /// Encrypt item name → barcode payload (offline-safe)
  static String generate(String itemName) {
    final normalized = normalize(itemName);
    return _encrypter.encrypt(normalized, iv: _iv).base64;
  }

  // ================= DECRYPT =================
  /// Decrypt barcode payload → normalized item name
  static String decrypt(String barcodeValue) {
    return _encrypter.decrypt(
      Encrypted.fromBase64(barcodeValue),
      iv: _iv,
    );
  }

  // ================= BARCODE IMAGE (PNG) =================
  /// Generates a PNG barcode image as Uint8List
  static Uint8List generateBarcodePng(
      String barcodeValue, {
        int width = 300,
        int height = 100,
      }) {
    final barcode = Barcode.code128();

    // 1️⃣ Create image buffer
    final image = img.Image(width: width, height: height);

    // 2️⃣ Draw barcode into image
    drawBarcode(
      image,
      barcode,
      barcodeValue,
      x: 0,
      y: 0,
      width: width,
      height: height,
    );

    // 3️⃣ Encode PNG
    return Uint8List.fromList(img.encodePng(image));
  }
}
