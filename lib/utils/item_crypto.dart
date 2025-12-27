import 'package:encrypt/encrypt.dart';

class ItemCrypto {
  // ⚠️ IMPORTANT:
  // - Keep this key PRIVATE
  // - 32 chars = AES-256
  // - Do NOT change once deployed (or old data breaks)
  static final Key _key =
  Key.fromUtf8('AIMS-INVENTORY-ITEM-KEY-32CH');

  // Fixed IV so encryption is deterministic
  // (barcode must always map to same item)
  static final IV _iv = IV.fromUtf8('AIMS-INVENTORY-IV');

  static final Encrypter _encrypter =
  Encrypter(AES(_key, mode: AESMode.cbc));

  /// 🔐 Encrypt item name → barcode-safe string
  static String encryptItemName(String itemName) {
    final normalized = _normalize(itemName);
    final encrypted = _encrypter.encrypt(normalized, iv: _iv);
    return encrypted.base64; // barcode-friendly
  }

  /// 🔓 Decrypt barcode → original item key
  static String decryptBarcode(String barcodeValue) {
    final encrypted = Encrypted.fromBase64(barcodeValue);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// Normalize so:
  /// "Vitamin C", "vitaminc", "Vitamin-C" → SAME value
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }
}
