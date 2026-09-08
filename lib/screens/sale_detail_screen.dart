import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/business_settings.dart";
import "../models/sale.dart";
import "../services/api_service.dart";
import "../services/thermal_printer_service.dart";
import "../utils/receipt_print.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/bill_receipt_card.dart";
import "../widgets/printer_setup_sheet.dart";

class SaleDetailScreen extends StatefulWidget {
  const SaleDetailScreen({super.key, required this.api, required this.saleId});

  final ApiService api;
  final int saleId;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  SaleRecord? _sale;
  BusinessSettings? _settings;
  var _loading = true;
  var _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sale = await widget.api.fetchSale(id: widget.saleId);
      final settings = await widget.api.fetchBusinessSettings();
      if (!mounted) return;
      setState(() {
        _sale = sale;
        _settings = settings;
      });
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

  Future<void> _print() async {
    final sale = _sale;
    final settings = _settings;
    if (sale == null || settings == null || _printing) return;

    setState(() => _printing = true);
    try {
      if (!ThermalPrinterService.isSupported) {
        showErrorToast(context, "Bluetooth print not available here");
        return;
      }
      var printer = await ThermalPrinterService.instance.getSavedPrinter();
      if (!mounted) return;
      printer ??= await showPrinterSetupSheet(context);
      if (printer == null || !mounted) return;

      showSuccessToast(context, "Connecting to printer...");
      await printSaleReceiptThermal(
        mac: printer.mac,
        settings: settings,
        saleId: sale.id,
        saleDate: sale.saleDate,
        items: sale.items
            .map(
              (item) => ReceiptLineItem(
                productName: "${item.productName} · ${item.flavor}",
                variantName: item.variantLabel,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
              ),
            )
            .toList(),
        totalAmount: sale.totalAmount,
        customerName: sale.displayCustomer,
        channel: sale.customerType == "shop" ? "Shop" : "Walk-in",
        returnsCredit: sale.returnsCreditApplied,
        previousBalance: sale.previousBalance,
        paidAmount: sale.paidAmount,
        notes: sale.notes,
      );
      await widget.api.markSalePrinted(id: sale.id);
      if (!mounted) return;
      showSuccessToast(context, "Bill sent to printer");
      await _load();
    } on ThermalPrinterException catch (error) {
      if (!mounted) return;
      showErrorToast(context, printerMessage(error.code));
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = _sale;
    final settings = _settings;

    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Sale #${widget.saleId}",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
      ),
      body: _loading || sale == null || settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                BillReceiptCard(
                  settings: settings,
                  billNumberLabel: "Sale #${sale.id}",
                  saleDate: sale.saleDate,
                  items: sale.items
                      .map(
                        (item) => BillLineItem(
                          productName:
                              "${item.productName} · ${item.flavor}",
                          variantName: item.variantLabel,
                          quantity: item.quantity,
                          unitPrice: item.unitPrice,
                        ),
                      )
                      .toList(),
                  totalAmount: sale.totalAmount,
                  customerName: sale.displayCustomer,
                  channel: sale.customerType == "shop" ? "Shop" : "Walk-in",
                  returnsAmount: sale.returnsCreditApplied,
                  previousBalance: sale.previousBalance,
                  paidAmount: sale.paidAmount,
                  remainingAfter: sale.remainingAfter,
                  notes: sale.notes,
                ),
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: _printing ? "Printing..." : "Print bill",
                  loading: _printing,
                  onPressed: _printing ? null : _print,
                ),
              ],
            ),
    );
  }
}
