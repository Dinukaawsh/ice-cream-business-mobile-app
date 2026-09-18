import "package:flutter/material.dart";

import "../models/sale.dart";
import "../services/api_service.dart";
import "../widgets/app_chrome.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "sale_detail_screen.dart";
import "sale_screen.dart";

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  List<SaleRecord> _sales = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sales = await widget.api.fetchSales();
      if (!mounted) return;
      setState(() => _sales = sales);
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, "0");
    final day = local.day.toString().padLeft(2, "0");
    return "${local.year}-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: "Sales",
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SaleScreen(api: widget.api)),
          );
          if (mounted) await _load();
        },
        backgroundColor: AuthColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New sale"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sales.isEmpty
                  ? AppEmptyState(
                      icon: Icons.point_of_sale_outlined,
                      title: "No sales yet",
                      message: "Start a sale to see bills and history here.",
                      actionLabel: "New sale",
                      onAction: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SaleScreen(api: widget.api),
                          ),
                        );
                        if (mounted) await _load();
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _sales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        return AppSurfaceCard(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SaleDetailScreen(
                                  api: widget.api,
                                  saleId: sale.id,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const AppIconBadge(icon: Icons.receipt_long),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale.displayCustomer,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AuthColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${_dateLabel(sale.saleDate)} · Sale #${sale.id}",
                                      style: const TextStyle(
                                        color: AuthColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (sale.remainingAfter > 0) ...[
                                      const SizedBox(height: 6),
                                      AppStatusChip(
                                        label:
                                            "Still unpaid LKR ${sale.remainingAfter.toStringAsFixed(0)}",
                                        tone: AppChipTone.warning,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                "LKR ${sale.totalAmount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AuthColors.primaryDeep,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
