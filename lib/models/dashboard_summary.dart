class DashboardPoint {
  const DashboardPoint({required this.label, required this.amount});

  final String label;
  final double amount;

  factory DashboardPoint.fromJson(Map<String, dynamic> json) {
    return DashboardPoint(
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardFlavor {
  const DashboardFlavor({
    required this.name,
    required this.amount,
    required this.share,
  });

  final String name;
  final double amount;
  final double share;

  factory DashboardFlavor.fromJson(Map<String, dynamic> json) {
    return DashboardFlavor(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      share: (json['share'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.isSample,
    required this.todaySales,
    required this.weekSales,
    required this.monthSales,
    required this.ordersToday,
    required this.returnsCreditToday,
    required this.avgTicket,
    required this.weekly,
    required this.topFlavors,
    required this.channelSplit,
  });

  final bool isSample;
  final double todaySales;
  final double weekSales;
  final double monthSales;
  final int ordersToday;
  final double returnsCreditToday;
  final double avgTicket;
  final List<DashboardPoint> weekly;
  final List<DashboardFlavor> topFlavors;
  final List<DashboardPoint> channelSplit;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      isSample: json['isSample'] as bool? ?? false,
      todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0,
      weekSales: (json['weekSales'] as num?)?.toDouble() ?? 0,
      monthSales: (json['monthSales'] as num?)?.toDouble() ?? 0,
      ordersToday: json['ordersToday'] as int? ?? 0,
      returnsCreditToday:
          (json['returnsCreditToday'] as num?)?.toDouble() ?? 0,
      avgTicket: (json['avgTicket'] as num?)?.toDouble() ?? 0,
      weekly: (json['weekly'] as List<dynamic>? ?? [])
          .map((item) => DashboardPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      topFlavors: (json['topFlavors'] as List<dynamic>? ?? [])
          .map(
            (item) => DashboardFlavor.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      channelSplit: (json['channelSplit'] as List<dynamic>? ?? [])
          .map((item) => DashboardPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
