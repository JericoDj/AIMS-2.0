import 'dart:typed_data';
import 'package:image/image.dart' as img;

class BarcodePngResult {
  final Uint8List pngBytes;
  final img.Image image;

  BarcodePngResult({
    required this.pngBytes,
    required this.image,
  });
}
