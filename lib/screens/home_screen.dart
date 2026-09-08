import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/business_settings.dart";
import "../models/dashboard_summary.dart";
import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/confirm_dialog.dart";
import "business_settings_screen.dart";
import "customers_screen.dart";
import "login_screen.dart";
import "printer_settings_screen.dart";
import "products_screen.dart";
import "reports_screen.dart";
import "returns_screen.dart";
import "sale_screen.dart";
import "sales_list_screen.dart";

const _sampleDashboardJson = {
  "isSample": true,
  "todaySales": 18450,
  "weekSales": 96200,
  "monthSales": 386400,
  "ordersToday": 24,
  "returnsCreditToday": 1450,
  "avgTicket": 768.75,
  "weekly": [
    {"label": "Mon", "amount": 11200},
    {"label": "Tue", "amount": 9800},
    {"label": "Wed", "amount": 14300},
    {"label": "Thu", "amount": 12600},
    {"label": "Fri", "amount": 16800},
    {"label": "Sat", "amount": 19200},
    {"label": "Sun", "amount": 12300},
  ],
  "topFlavors": [
    {"name": "Vanilla", "amount": 28600, "share": 0.3},
    {"name": "Chocolate", "amount": 24100, "share": 0.25},
    {"name": "Strawberry", "amount": 18400, "share": 0.19},
    {"name": "Mango", "amount": 15200, "share": 0.16},
    {"name": "Other", "amount": 9900, "share": 0.1},
  ],
  "channelSplit": [
    {"label": "Walk-in", "amount": 54800},
    {"label": "Shop", "amount": 41400},
  ],
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.user});

  final ApiService api;
  final SessionUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BusinessSettings? _settings;
  DashboardSummary? _dashboard;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final settings = await widget.api.fetchBusinessSettings();
      DashboardSummary dashboard;
      try {
        dashboard = await widget.api.fetchDashboardSummary();
      } catch (_) {
        dashboard = DashboardSummary.fromJson(_sampleDashboardJson);
      }
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _dashboard = dashboard;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _dashboard = DashboardSummary.fromJson(_sampleDashboardJson);
      });
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showConfirmDialog(
      context,
      title: "Log out?",
      message: "You will need to sign in again to manage your business.",
      confirmLabel: "Log out",
      isDanger: true,
    );
    if (!shouldLogout || !mounted) return;
    await widget.api.clearToken();
    if (!mounted) return;
    showSuccessToast(context, "Logged out");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessSettingsScreen(api: widget.api),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  String _money(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0).replaceAllMapped(
            RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
            (match) => "${match[1]},",
          );
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final dash = _dashboard;
    final logoUrl = settings?.logoUrl;
    final businessName = settings?.businessName ?? "Ice Cream";

    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Dashboard",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: "Bluetooth printer",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrinterSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.print_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SaleScreen(api: widget.api)),
          );
        },
        backgroundColor: AuthColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text("New sale"),
      ),
      drawer: Drawer(
        backgroundColor: AuthColors.frost,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          logoUrl != null ? NetworkImage(logoUrl) : null,
                      child: logoUrl == null
                          ? const Icon(
                              Icons.icecream,
                              color: Color(0xFF2563EB),
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      businessName,
                      style: GoogleFonts.fraunces(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings?.ownerName ?? widget.user.name,
                      style: const TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.user.email,
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text("Dashboard"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.icecream_outlined),
                title: const Text("Products"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductsScreen(api: widget.api),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text("Customers"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomersScreen(api: widget.api),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.point_of_sale_outlined),
                title: const Text("Sales"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SalesListScreen(api: widget.api),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_return_outlined),
                title: const Text("Returns"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReturnsScreen(api: widget.api),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded),
                title: const Text("Reports"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportsScreen(api: widget.api),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text("Business settings"),
                onTap: () {
                  Navigator.pop(context);
                  _openSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_rounded),
                title: const Text("Bluetooth printer"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrinterSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text("Bill preview"),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final loaded =
                        settings ?? await widget.api.fetchBusinessSettings();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BillPreviewScreen(settings: loaded),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    showErrorToast(
                      context,
                      error.toString().replaceFirst("Exception: ", ""),
                    );
                  }
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFB91C1C)),
                title: const Text(
                  "Log out",
                  style: TextStyle(color: Color(0xFFB91C1C)),
                ),
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ),
      body: _loading && dash == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _HeroHeader(
                    businessName: businessName,
                    ownerName: settings?.ownerName ?? widget.user.name,
                    logoUrl: logoUrl,
                    isSample: dash?.isSample ?? true,
                  ),
                  const SizedBox(height: 18),
                  if (dash != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _KpiTile(
                            label: "Today",
                            value: "LKR ${_money(dash.todaySales)}",
                            hint: "${dash.ordersToday} orders",
                            color: AuthColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiTile(
                            label: "This week",
                            value: "LKR ${_money(dash.weekSales)}",
                            hint: "7-day total",
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _KpiTile(
                            label: "Avg ticket",
                            value: "LKR ${_money(dash.avgTicket)}",
                            hint: "Per order today",
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiTile(
                            label: "Returns",
                            value: "LKR ${_money(dash.returnsCreditToday)}",
                            hint: "Credit today",
                            color: const Color(0xFFBE123C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ChartPanel(
                      title: "Weekly sales",
                      subtitle: dash.isSample
                          ? "Sample preview until you record sales"
                          : "Last 7 days",
                      child: SizedBox(
                        height: 210,
                        child: _WeeklyBars(points: dash.weekly),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChartPanel(
                      title: "Top flavors",
                      subtitle: "Share of recent sales",
                      child: SizedBox(
                        height: 210,
                        child: _FlavorDonut(flavors: dash.topFlavors),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChartPanel(
                      title: "Sales by channel",
                      subtitle: "Walk-in vs shop",
                      child: SizedBox(
                        height: 180,
                        child: _ChannelBars(points: dash.channelSplit),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Quick links",
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AuthColors.blueberry,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _QuickChip(
                          icon: Icons.add_shopping_cart_rounded,
                          label: "New sale",
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SaleScreen(api: widget.api),
                              ),
                            );
                          },
                        ),
                        _QuickChip(
                          icon: Icons.icecream_outlined,
                          label: "Products",
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductsScreen(api: widget.api),
                              ),
                            );
                          },
                        ),
                        _QuickChip(
                          icon: Icons.people_outline,
                          label: "Customers",
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomersScreen(api: widget.api),
                              ),
                            );
                          },
                        ),
                        _QuickChip(
                          icon: Icons.assignment_return_outlined,
                          label: "Returns",
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReturnsScreen(api: widget.api),
                              ),
                            );
                          },
                        ),
                        _QuickChip(
                          icon: Icons.bar_chart_rounded,
                          label: "Reports",
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportsScreen(api: widget.api),
                              ),
                            );
                          },
                        ),
                        _QuickChip(
                          icon: Icons.storefront_outlined,
                          label: "Settings",
                          onTap: _openSettings,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.businessName,
    required this.ownerName,
    required this.logoUrl,
    required this.isSample,
  });

  final String businessName;
  final String ownerName;
  final String? logoUrl;
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AuthColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
            child: logoUrl == null
                ? const Icon(Icons.icecream, color: Color(0xFF2563EB), size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Hi $ownerName — here's today's scoop",
                  style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 13),
                ),
                if (isSample) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      "Sample charts · live after first sale",
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
  });

  final String label;
  final String value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AuthColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: AuthColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: AuthColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AuthColors.blueberry,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AuthColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.points});

  final List<DashboardPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text("No sales yet"));
    }
    final maxY = points
        .map((point) => point.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AuthColors.primary.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[index].label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AuthColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].amount,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF93C5FD), Color(0xFF2563EB)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FlavorDonut extends StatelessWidget {
  const _FlavorDonut({required this.flavors});

  final List<DashboardFlavor> flavors;

  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFF0F766E),
    Color(0xFFF472B6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    if (flavors.isEmpty) {
      return const Center(child: Text("No flavor data yet"));
    }
    final total = flavors.fold<double>(0, (sum, item) => sum + item.amount);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: [
                for (var i = 0; i < flavors.length; i++)
                  PieChartSectionData(
                    color: _colors[i % _colors.length],
                    value: flavors[i].amount <= 0 && total <= 0
                        ? flavors[i].share
                        : flavors[i].amount,
                    title: "",
                    radius: 28,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < flavors.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flavors[i].name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        "${(flavors[i].share * 100).round()}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AuthColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelBars extends StatelessWidget {
  const _ChannelBars({required this.points});

  final List<DashboardPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text("No channel data yet"));
    }
    final maxY = points
        .map((point) => point.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.25,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[index].label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].amount,
                  width: 42,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: i == 0
                        ? const [Color(0xFF93C5FD), Color(0xFF2563EB)]
                        : const [Color(0xFF99F6E4), Color(0xFF0F766E)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AuthColors.primaryDeep),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AuthColors.blueberry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
