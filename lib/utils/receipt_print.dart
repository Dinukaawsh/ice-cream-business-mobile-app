import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../models/business_settings.dart';
import '../services/thermal_printer_service.dart';

class ReceiptLineItem {
  const ReceiptLineItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.variantName,
  });

  final String productName;
  final String? variantName;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  String get displayName {
    final variant = variantName?.trim();
    if (variant == null || variant.isEmpty) return productName;
    return '$productName ($variant)';
  }
}

/// Thermal printers only accept Latin-1. Strip Unicode (Sinhala, …, etc.).
String thermalText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune == 0x2026) {
      buffer.write('...');
    } else if (rune <= 0xFF) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

String formatMoney(double amount) => amount.toStringAsFixed(2);

/// 80 mm thermal paper — 48 characters per line (font A).
const thermalLineWidth = 48;

List<String> wrapThermalText(String text, int width) {
  final sanitized = thermalText(text).trim();
  if (sanitized.isEmpty) return const [];

  final lines = <String>[];
  final words = sanitized.split(RegExp(r'\s+'));
  var current = '';

  for (final word in words) {
    final candidate = current.isEmpty ? word : '$current $word';
    if (candidate.length <= width) {
      current = candidate;
      continue;
    }

    if (current.isNotEmpty) {
      lines.add(current);
      current = '';
    }

    if (word.length <= width) {
      current = word;
    } else {
      var start = 0;
      while (start < word.length) {
        lines.add(word.substring(start, (start + width).clamp(0, word.length)));
        start += width;
      }
    }
  }

  if (current.isNotEmpty) lines.add(current);
  return lines;
}

String formatReceiptDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// ESC/POS text receipt — business header + thank-you footer (logo never printed).
Future<List<int>> buildSaleReceiptEscPos({
  required BusinessSettings settings,
  required int saleId,
  required DateTime saleDate,
  required List<ReceiptLineItem> items,
  required double totalAmount,
  String? customerName,
  String channel = 'Walk-in',
  double returnsCredit = 0,
  double previousBalance = 0,
  double paidAmount = 0,
  String? notes,
}) async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile);
  final bytes = <int>[...generator.reset()];

  void writeln(
    String text, {
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) {
    final parts = wrapThermalText(text, thermalLineWidth);
    if (parts.isEmpty) return;
    for (final part in parts) {
      bytes.addAll(
        generator.text(
          part,
          styles: PosStyles(bold: bold, align: align),
        ),
      );
    }
  }

  void center(String text, {bool bold = false}) {
    writeln(text, bold: bold, align: PosAlign.center);
  }

  void line(String text, {bool bold = false}) => writeln(text, bold: bold);

  void amountRow(String left, String right, {bool bold = false}) {
    bytes.addAll(
      generator.row([
        PosColumn(
          text: thermalText(left),
          width: 7,
          styles: PosStyles(bold: bold),
        ),
        PosColumn(
          text: thermalText(right),
          width: 5,
          styles: PosStyles(bold: bold, align: PosAlign.right),
        ),
      ]),
    );
  }

  void divider() => line('-' * thermalLineWidth);
  void blank() => bytes.addAll(generator.feed(1));

  final netToday = totalAmount - returnsCredit;
  final amountDue = previousBalance + netToday;
  final remaining = (amountDue - paidAmount).clamp(0, double.infinity);

  center(settings.businessName, bold: true);
  if (settings.ownerName != null && settings.ownerName!.isNotEmpty) {
    center(settings.ownerName!);
  }
  if (settings.address.isNotEmpty) center(settings.address);
  if (settings.phone.isNotEmpty) center('Tel: ${settings.phone}');
  if (settings.email != null && settings.email!.isNotEmpty) {
    center(settings.email!);
  }

  blank();
  center('Sale #$saleId', bold: true);
  divider();

  line('Channel', bold: true);
  line(channel);
  if (customerName != null && customerName.isNotEmpty) {
    blank();
    line('Customer', bold: true);
    line(customerName);
  }
  blank();
  line(formatReceiptDate(saleDate));
  divider();

  for (final item in items) {
    line(item.displayName);
    amountRow(
      '${formatMoney(item.unitPrice)} x ${item.quantity}',
      formatMoney(item.lineTotal),
    );
  }

  divider();
  amountRow('Subtotal', formatMoney(totalAmount));
  if (returnsCredit > 0) {
    amountRow('Returns credit', '-${formatMoney(returnsCredit)}');
    amountRow('Net today', formatMoney(netToday));
  }
  if (previousBalance > 0) {
    amountRow('Previous unpaid', formatMoney(previousBalance));
  }
  amountRow('Total due', formatMoney(amountDue), bold: true);
  amountRow('Paid', formatMoney(paidAmount));
  amountRow('Remaining', formatMoney(remaining.toDouble()), bold: true);

  if (notes != null && notes.isNotEmpty) {
    blank();
    line('Notes: $notes');
  }

  blank();
  center('Thank you for your business!');
  bytes.addAll(generator.feed(5));
  return bytes;
}

Future<void> printSaleReceiptThermal({
  required String mac,
  required BusinessSettings settings,
  required int saleId,
  required DateTime saleDate,
  required List<ReceiptLineItem> items,
  required double totalAmount,
  String? customerName,
  String channel = 'Walk-in',
  double returnsCredit = 0,
  double previousBalance = 0,
  double paidAmount = 0,
  String? notes,
}) async {
  final bytes = await buildSaleReceiptEscPos(
    settings: settings,
    saleId: saleId,
    saleDate: saleDate,
    items: items,
    totalAmount: totalAmount,
    customerName: customerName,
    channel: channel,
    returnsCredit: returnsCredit,
    previousBalance: previousBalance,
    paidAmount: paidAmount,
    notes: notes,
  );

  await ThermalPrinterService.instance.printEscPosReceipt(
    mac: mac,
    bytes: bytes,
  );
}
