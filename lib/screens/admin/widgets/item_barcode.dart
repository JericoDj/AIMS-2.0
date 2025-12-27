import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class ItemBarcode extends StatelessWidget {
  final String barcodeValue;

  const ItemBarcode({
    super.key,
    required this.barcodeValue,
  });

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: Barcode.code128(), // universal scanner support
      data: barcodeValue,
      width: 220,
      height: 80,
      drawText: true, // shows value below barcode
    );
  }
}
