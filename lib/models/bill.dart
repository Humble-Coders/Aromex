// Keep your existing Bill class and imports
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:aromex/models/bill_customer.dart';
import 'package:aromex/models/bill_item.dart';
import 'package:aromex/util.dart';

class Bill {
  final String storeName = "Aromex Communication";
  final String storeAddress = "13898 64 Ave,\nUnit 101";
  final String storePhone = "+1 672-699-0009";
  final DateTime time;
  final BillCustomer customer;
  final String orderNumber;
  List<BillItem> items;
  String? note;
  final double? adjustment;

  Bill({
    required this.time,
    required this.customer,
    required this.orderNumber,
    required this.items,
    this.adjustment,
    this.note,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPriceValue);
  }

  String get subtotalFormatted {
    return formatCurrency(subtotal, decimals: 2, showTrail: true);
  }

  double get total {
    return subtotal - (adjustment ?? 0.0);
  }

  String get totalFormatted {
    return formatCurrency(total, decimals: 2, showTrail: true);
  }

  String get adjustmentFormatted {
    return formatCurrency(adjustment ?? 0.0, decimals: 2, showTrail: true);
  }
}

// Now replace your existing PDF generation methods with these improved versions:
Future<void> generatePdfInvoice(Bill bill) async {
  try {
    final pdfData = await _generatePdfInvoice(bill);
    final fileName = "Invoice${bill.orderNumber}${formatDate(bill.time).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.pdf";
    print("Attempting to save PDF: $fileName");    print("Attempting to save PDF: $fileName");
    await savePdfCrossPlatform(pdfData, fileName);
    print("PDF saved successfully");
  } catch (e) {
    print("Error in generatePdfInvoice: $e");
    throw e;
  }
}

Future<void> savePdfCrossPlatform(Uint8List bytes, String fileName) async {
  try {
    if (kIsWeb) {
      // Web implementation
      final file = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/pdf',
      );
      await file.saveTo(file.name);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop implementation
      final saveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'PDF Documents',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
          ),
        ],
      );

      if (saveLocation != null) {
        print("Saving to path: ${saveLocation.path}");
        final file = File(saveLocation.path);
        await file.writeAsBytes(bytes);
        print("File saved successfully to: ${saveLocation.path}");
      } else {
        print("Save operation canceled by user");
      }
    } else {
      // Mobile implementation
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      print("Saving to mobile path: $path");
      final file = File(path);
      await file.writeAsBytes(bytes);
      print("File saved successfully to: $path");
    }
  } catch (e) {
    print("Error in savePdfCrossPlatform: $e");
    throw e;
  }
}

Future<Uint8List> _generatePdfInvoice(Bill bill) async {
  final pdf = pw.Document();

  final baseTextStyle = pw.TextStyle(fontSize: 10);
  final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  final title = pw.TextStyle(
    fontSize: 24,
    color: PdfColors.blue900,
    fontWeight: pw.FontWeight.bold,
  );

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: baseTextStyle,
        ),
      ),
      build: (context) => [
        // Header
        pw.Text(bill.storeName, style: bold.copyWith(fontSize: 14)),
        pw.Text(bill.storeAddress, style: baseTextStyle),
        pw.Text(bill.storePhone, style: baseTextStyle),
        pw.SizedBox(height: 16),

        // Invoice Title + Metadata
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice', style: title),
            pw.SizedBox(height: 4),
            pw.Text(
              formatDate(bill.time),
              style: pw.TextStyle(color: PdfColors.red, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice for', style: bold),
                    pw.Text(bill.customer.name, style: baseTextStyle),
                    pw.Text(bill.customer.address, style: baseTextStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice #', style: bold),
                    pw.Text(bill.orderNumber, style: baseTextStyle),
                  ],
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),

        // Table Header
        pw.Container(
          color: PdfColors.grey300,
          padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text("Description", style: bold),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  "Qty",
                  style: bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  "Unit price",
                  style: bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  "Total price",
                  style: bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Product Rows - Check if items exist and print debugging info
        ...bill.items.isNotEmpty
            ? bill.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 1;
          final bgColor = isEven ? PdfColors.grey100 : PdfColors.white;

          return pw.Container(
            color: bgColor,
            padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    item.title,
                    style: baseTextStyle,
                    softWrap: true,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    "${item.quantity}",
                    textAlign: pw.TextAlign.right,
                    style: baseTextStyle,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    item.unitPrice,
                    textAlign: pw.TextAlign.right,
                    style: baseTextStyle,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    item.totalPrice,
                    textAlign: pw.TextAlign.right,
                    style: baseTextStyle,
                  ),
                ),
              ],
            ),
          );
        })
            : [pw.Text("No items found", style: baseTextStyle)],

        pw.SizedBox(height: 8),
        pw.Divider(),

        // Notes
        if (bill.note != null && bill.note!.isNotEmpty)
          pw.Text("Notes: ${bill.note}", style: baseTextStyle),
        pw.SizedBox(height: 16),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  children: [
                    pw.Text("Subtotal:  ", style: bold),
                    pw.Text(bill.subtotalFormatted),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text("Adjustments:  ", style: bold),
                    pw.Text(bill.adjustmentFormatted),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Text("Total:  ", style: bold),
                    pw.Text(
                      bill.totalFormatted,
                      style: bold.copyWith(
                        fontSize: 18,
                        color: PdfColors.pink800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}