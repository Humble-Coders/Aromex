import 'package:aromex/models/bill_customer.dart';
import 'package:aromex/models/bill_item.dart';
import 'package:aromex/util.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:file_selector/file_selector.dart';

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

Future<void> generatePdfInvoice(Bill bill) async {
  final pdfData = await _generatePdfInvoice(bill);
  final fileName = "Invoice-${bill.orderNumber}-${formatDate(bill.time)}.pdf";
  print(fileName);
  await savePdfCrossPlatform(pdfData, fileName);
}

Future<void> savePdfCrossPlatform(Uint8List bytes, String fileName) async {
  final file = XFile.fromData(
    bytes,
    name: fileName,
    mimeType: 'application/pdf',
  );

  if (!kIsWeb) {
    final location = await getSaveLocation(suggestedName: fileName);
    if (location != null) {
      await file.saveTo(location.path);
    }
  } else {
    await file.saveTo(file.name);
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
      footer:
          (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: baseTextStyle,
            ),
          ),
      build:
          (context) => [
            /// Header
            pw.Text(bill.storeName, style: bold.copyWith(fontSize: 14)),
            pw.Text(bill.storeAddress, style: baseTextStyle),
            pw.Text(bill.storePhone, style: baseTextStyle),
            pw.SizedBox(height: 16),

            /// Invoice Title + Metadata
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

            /// Table Header
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

            /// Product Rows 
            ...bill.items.asMap().entries.map((entry) {
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
            }),

            pw.SizedBox(height: 8),
            pw.Divider(),

            /// Notes
            if (bill.note != null)
              pw.Text("Notes: ${bill.note}", style: baseTextStyle),
            pw.SizedBox(height: 16),

            /// Totals
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
  );

  return pdf.save();
}
