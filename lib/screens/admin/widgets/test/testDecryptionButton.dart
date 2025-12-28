import 'package:flutter/material.dart';
import '../../../../controllers/barCodeController.dart';

class TestEncryptionDecryptionButton extends StatelessWidget {
  final String input;

  const TestEncryptionDecryptionButton({
    super.key,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Test Encrypt & Decrypt'),
      onPressed: () {
        try {
          debugPrint('==============================');
          debugPrint('🔐 ENCRYPT / DECRYPT TEST');

          // 1️⃣ Original input
          debugPrint('📥 ORIGINAL INPUT: $input');
          final String normalized =
          BarcodeController.normalizeForKey(input);
          debugPrint('🧹 NORMALIZED: $normalized');

          // 2️⃣ Encrypt
          final String encrypted =
          BarcodeController.generate(input);
          debugPrint('🔒 ENCRYPTED VALUE:');
          debugPrint(encrypted);

          // 3️⃣ Decrypt
          final String decrypted =
          BarcodeController.decrypt(encrypted);
          debugPrint('🔓 DECRYPTED VALUE:');
          debugPrint(decrypted);

          // 4️⃣ Validate
          final bool passed = decrypted == normalized;

          if (passed) {
            debugPrint('✅ ENCRYPTION & DECRYPTION PASSED');
          } else {
            debugPrint('❌ ENCRYPTION & DECRYPTION FAILED');
            debugPrint('EXPECTED: $normalized');
            debugPrint('ACTUAL  : $decrypted');
          }

          debugPrint('==============================');

          assert(
          passed,
          '❌ Encrypt/Decrypt round-trip failed',
          );
        } catch (e, s) {
          debugPrint('❌ TEST ERROR: $e');
          debugPrintStack(stackTrace: s);
        }
      },
    );
  }
}
