import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:barcode_image/barcode_image.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

import '../models/BarcodePngResult.dart';

class BarcodeController {
  // =========================================================
  // 🔐 AES CONFIG (RAW 32-BYTE KEY — NEVER CHANGE IN PROD)
  // =========================================================
  static final Key _key = Key(
    Uint8List.fromList([
      0x41, 0x49, 0x4D, 0x53, 0x2D, 0x42, 0x41, 0x52,
      0x43, 0x4F, 0x44, 0x45, 0x2D, 0x4B, 0x45, 0x59,
      0x2D, 0x33, 0x32, 0x2D, 0x42, 0x59, 0x54, 0x45,
      0x53, 0x2D, 0x4F, 0x4E, 0x4C, 0x59, 0x21, 0x21,
    ]),
  );

  static final Encrypter _encrypter =
  Encrypter(AES(_key, mode: AESMode.cbc));

  // =========================================================
  // 🔎 NORMALIZATION — SEARCH / DEDUPE ONLY
  // =========================================================
  static String normalizeForKey(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // =========================================================
  // 🔐 NORMALIZATION — CRYPTO (NON-DESTRUCTIVE)
  // =========================================================
  static String normalizeForCrypto(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // =========================================================
  // 🔐 ENCRYPT
  // =========================================================
  static String generate(String input) {
    final String clean = normalizeForCrypto(input);
    final IV iv = IV.fromSecureRandom(16);

    final Encrypted encrypted =
    _encrypter.encrypt(clean, iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  // =========================================================
  // 🔓 DECRYPT
  // =========================================================
  static String decrypt(String payload) {
    final parts = payload.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted payload');
    }

    return _encrypter.decrypt(
      Encrypted.fromBase64(parts[1]),
      iv: IV.fromBase64(parts[0]),
    );
  }

  // =========================================================
  // 🧾 CODE128 BARCODE → PNG (SHORT VALUE ONLY)
  // =========================================================
  static BarcodePngResult generateCode128(String value) {
    final barcode = Barcode.code128();

    final img.Image image = img.Image(
      width: 1200,
      height: 300,
    );

    // White background
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    drawBarcode(
      image,
      barcode,
      value,
      width: image.width,
      height: image.height,
    );

    final Uint8List pngBytes =
    Uint8List.fromList(img.encodePng(image));

    return BarcodePngResult(
      pngBytes: pngBytes,
      image: image,
    );
  }

  // =========================================================
// 📱 QR CODE → PNG (ANY LENGTH, ENCRYPTED OK)
// =========================================================
  // =========================================================
// 📱 QR CODE → PNG (qr_flutter)
// =========================================================
  static Future<Uint8List> generateQrPng(
      String data, {
        double size = 600,
      }) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Invalid QR data');
    }

    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final ui.Image image =
    await painter.toImage(size);

    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert QR to PNG');
    }

    return byteData.buffer.asUint8List();
  }







}
