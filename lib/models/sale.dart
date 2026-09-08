class CustomerItem {
  const CustomerItem({
    required this.id,
    required this.type,
    required this.name,
    required this.outstandingBalance,
    required this.returnCredit,
    this.phone,
    this.address,
    this.isActive = true,
  });

  final int id;
  final String type; // shop | person
  final String name;
  final String? phone;
  final String? address;
  final double outstandingBalance;
  final double returnCredit;
  final bool isActive;

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    return CustomerItem(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'person',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      outstandingBalance:
          (json['outstandingBalance'] as num?)?.toDouble() ?? 0,
      returnCredit: (json['returnCredit'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SaleLineItem {
  const SaleLineItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.flavor,
    required this.variantLabel,
    required this.quantity,
    required this.unitPrice,
  });

  final int productId;
  final int variantId;
  final String productName;
  final String flavor;
  final String variantLabel;
  final int quantity;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;

  factory SaleLineItem.fromJson(Map<String, dynamic> json) {
    return SaleLineItem(
      productId: json['productId'] as int,
      variantId: json['variantId'] as int,
      productName: json['productName'] as String? ?? '',
      flavor: json['flavor'] as String? ?? '',
      variantLabel: json['variantLabel'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.saleDate,
    required this.totalAmount,
    required this.previousBalance,
    required this.returnsCreditApplied,
    required this.paidAmount,
    required this.remainingAfter,
    required this.items,
    this.customerId,
    this.walkInName,
    this.customerName,
    this.customerType,
    this.customerPhone,
    this.customerAddress,
    this.notes,
    this.billPrinted = false,
  });

  final int id;
  final int? customerId;
  final String? walkInName;
  final String? customerName;
  final String? customerType;
  final String? customerPhone;
  final String? customerAddress;
  final DateTime saleDate;
  final double totalAmount;
  final double previousBalance;
  final double returnsCreditApplied;
  final double paidAmount;
  final double remainingAfter;
  final String? notes;
  final bool billPrinted;
  final List<SaleLineItem> items;

  String get displayCustomer {
    if (customerName != null && customerName!.isNotEmpty) return customerName!;
    if (walkInName != null && walkInName!.isNotEmpty) return walkInName!;
    return 'Walk-in';
  }

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'] as int,
      customerId: json['customerId'] as int?,
      walkInName: json['walkInName'] as String?,
      customerName: json['customerName'] as String?,
      customerType: json['customerType'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerAddress: json['customerAddress'] as String?,
      saleDate: DateTime.parse(json['saleDate'] as String),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      previousBalance: (json['previousBalance'] as num?)?.toDouble() ?? 0,
      returnsCreditApplied:
          (json['returnsCreditApplied'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAfter: (json['remainingAfter'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      billPrinted: json['billPrinted'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => SaleLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReportSummary {
  const ReportSummary({
    required this.from,
    required this.to,
    required this.totalSales,
    required this.totalPaid,
    required this.totalReturnsCreditApplied,
    required this.orderCount,
    required this.returnsRecorded,
    required this.returnCount,
    required this.daily,
    required this.soldProducts,
  });

  final DateTime from;
  final DateTime to;
  final double totalSales;
  final double totalPaid;
  final double totalReturnsCreditApplied;
  final int orderCount;
  final double returnsRecorded;
  final int returnCount;
  final List<({String day, double amount, int orders})> daily;
  final List<
      ({
        String productName,
        String flavor,
        String variantLabel,
        int quantity,
        double amount,
      })> soldProducts;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      totalReturnsCreditApplied:
          (json['totalReturnsCreditApplied'] as num?)?.toDouble() ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
      returnsRecorded: (json['returnsRecorded'] as num?)?.toDouble() ?? 0,
      returnCount: json['returnCount'] as int? ?? 0,
      daily: (json['daily'] as List<dynamic>? ?? [])
          .map(
            (item) => (
              day: (item as Map<String, dynamic>)['day'] as String? ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              orders: item['orders'] as int? ?? 0,
            ),
          )
          .toList(),
      soldProducts: (json['soldProducts'] as List<dynamic>? ?? [])
          .map(
            (item) => (
              productName:
                  (item as Map<String, dynamic>)['productName'] as String? ??
                      '',
              flavor: item['flavor'] as String? ?? '',
              variantLabel: item['variantLabel'] as String? ?? '',
              quantity: item['quantity'] as int? ?? 0,
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList(),
    );
  }
}
