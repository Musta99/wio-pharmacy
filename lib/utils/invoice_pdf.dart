import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/utils/format.dart';

Future<void> printSalesInvoice(
  PharmaOrder order,
  PharmacyProfile? profile,
) async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.name ?? 'Pharmacy Invoice',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (profile?.address != null)
                      pw.Text(
                        profile!.address!,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    pw.Text(
                      [
                        if (profile?.phone != null) profile!.phone!,
                        if (profile?.licenseNo != null)
                          'License ${profile!.licenseNo}',
                      ].join(' · '),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '#${order.id}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      DateTime.parse(
                        order.createdAt,
                      ).toLocal().toString().split(' ').first,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.black),
            pw.SizedBox(height: 12),
            pw.Text(
              'Bill To: ${order.patientName} · ${order.phone}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              order.address,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            if (order.delivery?.riderName != null)
              pw.Text(
                'Rider: ${order.delivery!.riderName}${order.delivery!.riderPhone != null ? ' · ${order.delivery!.riderPhone}' : ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.Text(
              'Payment: ${order.paymentMethod}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Item', bold: true),
                    _cell('Qty', bold: true, align: pw.TextAlign.center),
                    _cell('Unit', bold: true, align: pw.TextAlign.right),
                    _cell('Amount', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ...order.items.map(
                  (it) => pw.TableRow(
                    children: [
                      _cell(it.name),
                      _cell('${it.quantity}', align: pw.TextAlign.center),
                      _cell(formatBdt(it.unitPrice), align: pw.TextAlign.right),
                      _cell(
                        formatBdt(it.totalPrice),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _totalRow('Subtotal', formatBdt(order.subtotal)),
                    _totalRow('Tax', formatBdt(order.tax)),
                    if (order.discount != null && order.discount! > 0)
                      _totalRow('Discount', '-${formatBdt(order.discount!)}'),
                    pw.Divider(thickness: 2, color: PdfColors.black),
                    _totalRow(
                      'Total',
                      formatBdt(order.total),
                      bold: true,
                      big: true,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Text(
                'Thank you for your order.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (_) => doc.save());
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  pw.TextAlign align = pw.TextAlign.left,
}) => pw.Padding(
  padding: const pw.EdgeInsets.all(6),
  child: pw.Text(
    text,
    textAlign: align,
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

pw.Widget _totalRow(
  String label,
  String value, {
  bool bold = false,
  bool big = false,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 3),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: big ? 13 : 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: big ? 13 : 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    ],
  ),
);
