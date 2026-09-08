import 'package:flutter/material.dart';

import '../models/business_settings.dart';
import '../utils/receipt_print.dart';

class BillLineItem {
  const BillLineItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.variantName,
  });

  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  String get displayName {
    final variant = variantName?.trim();
    if (variant == null || variant.isEmpty) return productName;
    return '$productName ($variant)';
  }
}

/// On-screen bill preview matching Bakery receipt layout (no logo on bill).
class BillReceiptCard extends StatelessWidget {
  const BillReceiptCard({
    super.key,
    required this.settings,
    required this.billNumberLabel,
    required this.saleDate,
    required this.items,
    required this.totalAmount,
    this.customerName,
    this.channel = 'Walk-in',
    this.returns = const [],
    this.returnsAmount = 0,
    this.previousBalance = 0,
    this.paidAmount = 0,
    this.remainingAfter,
    this.notes,
    this.isPreview = false,
  });

  final BusinessSettings settings;
  final String billNumberLabel;
  final DateTime saleDate;
  final List<BillLineItem> items;
  final List<BillLineItem> returns;
  final double totalAmount;
  final String? customerName;
  final String channel;
  final double returnsAmount;
  final double previousBalance;
  final double paidAmount;
  final double? remainingAfter;
  final String? notes;
  final bool isPreview;

  double get netToday => totalAmount - returnsAmount;
  double get amountDue => previousBalance + netToday;
  double get remaining =>
      remainingAfter ?? (amountDue - paidAmount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final dateLabel = formatReceiptDate(saleDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFBFDBFE))),
            ),
            child: Column(
              children: [
                if (isPreview)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                Text(
                  settings.businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (settings.ownerName != null &&
                    settings.ownerName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    settings.ownerName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                if (settings.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    settings.address,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                if (settings.phone.isNotEmpty ||
                    (settings.email?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (settings.phone.isNotEmpty) 'Tel: ${settings.phone}',
                      if (settings.email?.isNotEmpty ?? false) settings.email!,
                    ].join(' • '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  billNumberLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Channel',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text(channel, style: const TextStyle(fontSize: 12)),
                if (customerName != null && customerName!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Customer',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  Text(customerName!, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 6),
                Text(dateLabel, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFBFDBFE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Add products to see them on the bill',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${formatMoney(item.unitPrice)} x ${item.quantity} = ${formatMoney(item.lineTotal)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 20, color: Color(0xFFBFDBFE)),
                if (returns.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Returns',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...returns.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${formatMoney(item.unitPrice)} x ${item.quantity} = ${formatMoney(item.lineTotal)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFBFDBFE)),
                ],
                _summaryRow('Subtotal', formatMoney(totalAmount)),
                if (returnsAmount > 0) ...[
                  _summaryRow(
                    'Returns credit',
                    '-${formatMoney(returnsAmount)}',
                    color: const Color(0xFFB91C1C),
                  ),
                  _summaryRow('Net', formatMoney(netToday)),
                ],
                if (previousBalance > 0)
                  _summaryRow(
                    'Previous unpaid',
                    formatMoney(previousBalance),
                    color: const Color(0xFFB45309),
                  ),
                _summaryRow(
                  'Total due',
                  formatMoney(amountDue),
                  bold: true,
                ),
                _summaryRow('Paid', formatMoney(paidAmount)),
                _summaryRow(
                  'Remaining',
                  formatMoney(remaining),
                  bold: true,
                  color: const Color(0xFFB91C1C),
                ),
                if (notes != null && notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Notes: $notes',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Thank you for your business!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 14 : 12,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 14 : 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
