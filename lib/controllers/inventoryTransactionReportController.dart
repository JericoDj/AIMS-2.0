import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../providers/items_provider.dart';
import '../models/ItemModel.dart';

class InventoryTransactionReportController {
  static const int expiryWarningDays = 30;

  static Future<void> generateInventoryReport(
      BuildContext context, {
        required DateTime start,
        required DateTime end,
      }) async {
    final inventoryProvider = context.read<InventoryProvider>();
    final items = inventoryProvider.items;

    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // ================= FILTERS =================
    final allItems = items;

    final lowStockItems = items.where((i) => i.isLowStock).toList();

    final outOfStockItems = items.where((i) => i.isOutOfStock).toList();

    final nearlyExpiryItems = items.where((item) {
      final expiry = item.nearestExpiry;
      if (expiry == null) return false;
      final daysLeft = expiry.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= expiryWarningDays;
    }).toList();

    // ================= PDF SETUP =================
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pw.Widget buildTable(String title, List<ItemModel> data) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$title (${data.length})',
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
          pw.SizedBox(height: 6),
          data.isEmpty
              ? pw.Text(
            'No records',
            style: pw.TextStyle(font: font, fontSize: 10),
          )
              : pw.Table.fromTextArray(
            headerStyle:
            pw.TextStyle(font: boldFont, fontSize: 10),
            cellStyle:
            pw.TextStyle(font: font, fontSize: 9),
            headers: const [
              'Item',
              'Category',
              'Total Stock',
              'Low Stock Threshold',
              'Nearest Expiry',
            ],
            data: data.map((item) {
              return [
                item.name,
                item.category,
                item.totalStock.toString(),
                item.resolvedLowStockThreshold.toString(),
                item.nearestExpiry == null
                    ? '-'
                    : dateFormat.format(item.nearestExpiry!),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
        ],
      );
    }

    // ================= PAGE =================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'Inventory Report',
            style: pw.TextStyle(font: boldFont, fontSize: 22),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'From ${dateFormat.format(start)} to ${dateFormat.format(end)}',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.SizedBox(height: 20),

          // -------- SUMMARY --------
          pw.Text(
            'Summary',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Bullet(
            text: 'Total Items: ${allItems.length}',
            style: pw.TextStyle(font: font),
          ),
          pw.Bullet(
            text: 'Low Stock Items: ${lowStockItems.length}',
            style: pw.TextStyle(font: font),
          ),
          pw.Bullet(
            text: 'Out of Stock Items: ${outOfStockItems.length}',
            style: pw.TextStyle(font: font),
          ),
          pw.Bullet(
            text: 'Nearly Expiry Items: ${nearlyExpiryItems.length}',
            style: pw.TextStyle(font: font),
          ),

          pw.SizedBox(height: 20),

          // -------- TABLES --------
          buildTable('All Items', allItems),
          buildTable('Low Stock Items', lowStockItems),
          buildTable('Out of Stock Items', outOfStockItems),
          buildTable('Nearly Expiry Items', nearlyExpiryItems),
        ],
      ),
    );

    final pdfBytes =
    Uint8List.fromList(await pdf.save());

    _showPreviewDialog(
      context,
      pdfBytes,
      'inventory_report_${dateFormat.format(start)}_${dateFormat.format(end)}.pdf',
    );
  }

  // ================= PREVIEW =================
  static void _showPreviewDialog(
      BuildContext context,
      Uint8List bytes,
      String fileName,
      ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 1000,
          height: 650,
          child: PdfPreview(
            build: (_) async => bytes,
            allowPrinting: false,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: fileName,
          ),
        ),
      ),
    );
  }
}
