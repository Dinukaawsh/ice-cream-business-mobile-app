import "dart:typed_data";

import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

import "../config/brand.dart";
import "../models/business_settings.dart";
import "../models/sale.dart";

String _money(double value) => "LKR ${value.toStringAsFixed(0)}";

String _day(DateTime value) =>
    "${value.year.toString().padLeft(4, "0")}-${value.month.toString().padLeft(2, "0")}-${value.day.toString().padLeft(2, "0")}";

Future<Uint8List> buildReportPdf({
  required ReportSummary report,
  required DateTime from,
  required DateTime to,
  BusinessSettings? settings,
}) async {
  final shop = settings?.businessName.trim().isNotEmpty == true
      ? settings!.businessName.trim()
      : Brand.name;
  final doc = pw.Document();
  final range = "${_day(from)} to ${_day(to)}";

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            Brand.name,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.blue700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            shop,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Sales report · $range",
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Divider(color: PdfColors.blue200),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          "Page ${context.pageNumber} of ${context.pagesCount}",
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          headers: const ["Metric", "Value"],
          data: [
            ["Sales", _money(report.totalSales)],
            ["Paid", _money(report.totalPaid)],
            ["Orders", "${report.orderCount}"],
            [
              "Return credit applied",
              _money(report.totalReturnsCreditApplied),
            ],
            [
              "Returns recorded",
              "${_money(report.returnsRecorded)} (${report.returnCount})",
            ],
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Text(
          "Sold products",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (report.soldProducts.isEmpty)
          pw.Text(
            "No sales in this range",
            style: const pw.TextStyle(color: PdfColors.grey600),
          )
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 5,
            ),
            cellAlignments: {
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headers: const ["Product", "Flavor", "Variant", "Qty", "Amount"],
            data: [
              for (final item in report.soldProducts)
                [
                  item.productName,
                  item.flavor,
                  item.variantLabel,
                  "${item.quantity}",
                  _money(item.amount),
                ],
            ],
          ),
        pw.SizedBox(height: 22),
        pw.Text(
          "Daily breakdown",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (report.daily.isEmpty)
          pw.Text(
            "No daily totals in this range",
            style: const pw.TextStyle(color: PdfColors.grey600),
          )
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 5,
            ),
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
            headers: const ["Day", "Orders", "Amount"],
            data: [
              for (final item in report.daily)
                [item.day, "${item.orders}", _money(item.amount)],
            ],
          ),
      ],
    ),
  );

  return doc.save();
}

String reportPdfFileName({required DateTime from, required DateTime to}) {
  return "scooply-report-${_day(from)}-to-${_day(to)}.pdf";
}
