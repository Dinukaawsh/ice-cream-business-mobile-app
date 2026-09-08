import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/sale.dart";
import "../services/api_service.dart";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Sales",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SaleScreen(api: widget.api)),
          );
          if (mounted) await _load();
        },
        backgroundColor: AuthColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("New sale"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sales.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text("No sales yet")),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _sales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                          ),
                          tileColor: Colors.white,
                          title: Text(sale.displayCustomer),
                          subtitle: Text(
                            "${sale.saleDate.toIso8601String().split("T").first} · Sale #${sale.id}",
                          ),
                          trailing: Text(
                            "LKR ${sale.totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
                        );
                      },
                    ),
            ),
    );
  }
}
