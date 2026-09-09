import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:printing/printing.dart";

import "../models/business_settings.dart";
import "../models/sale.dart";
import "../services/api_service.dart";
import "../utils/report_pdf.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _from;
  late DateTime _to;
  ReportSummary? _report;
  BusinessSettings? _settings;
  var _loading = false;
  var _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final report = await widget.api.fetchReport(from: _from, to: _to);
      BusinessSettings? settings = _settings;
      try {
        settings = await widget.api.fetchBusinessSettings();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _report = report;
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

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _from = picked);
    await _load();
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _to = picked);
    await _load();
  }

  void _preset(String kind) {
    final now = DateTime.now();
    setState(() {
      if (kind == "today") {
        _from = DateTime(now.year, now.month, now.day);
        _to = now;
      } else if (kind == "month") {
        _from = DateTime(now.year, now.month, 1);
        _to = now;
      } else {
        _from = now.subtract(const Duration(days: 6));
        _to = now;
      }
    });
    _load();
  }

  Future<void> _downloadPdf() async {
    final report = _report;
    if (report == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await buildReportPdf(
        report: report,
        from: _from,
        to: _to,
        settings: _settings,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: reportPdfFileName(from: _from, to: _to),
      );
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Reports",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Download PDF",
            onPressed: _report == null || _loading || _exporting
                ? null
                : _downloadPdf,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ActionChip(label: const Text("Today"), onPressed: () => _preset("today")),
              ActionChip(label: const Text("7 days"), onPressed: () => _preset("week")),
              ActionChip(label: const Text("This month"), onPressed: () => _preset("month")),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickFrom,
                  child: Text("From ${_from.toIso8601String().split("T").first}"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTo,
                  child: Text("To ${_to.toIso8601String().split("T").first}"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (report != null) ...[
            _Stat("Sales", "LKR ${report.totalSales.toStringAsFixed(0)}"),
            _Stat("Paid", "LKR ${report.totalPaid.toStringAsFixed(0)}"),
            _Stat("Orders", "${report.orderCount}"),
            _Stat(
              "Return credit applied",
              "LKR ${report.totalReturnsCreditApplied.toStringAsFixed(0)}",
            ),
            _Stat(
              "Returns recorded",
              "LKR ${report.returnsRecorded.toStringAsFixed(0)} (${report.returnCount})",
            ),
            const SizedBox(height: 16),
            Text(
              "Sold products",
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (report.soldProducts.isEmpty)
              const Text(
                "No sales in this range",
                style: TextStyle(color: AuthColors.muted),
              )
            else
              ...report.soldProducts.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("${item.productName} · ${item.flavor}"),
                  subtitle: Text("${item.variantLabel} × ${item.quantity}"),
                  trailing: Text(
                    "LKR ${item.amount.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _exporting ? null : _downloadPdf,
              icon: const Icon(Icons.download_rounded),
              label: Text(_exporting ? "Preparing PDF..." : "Download PDF"),
            ),
            const SizedBox(height: 16),
            Text(
              "Daily breakdown",
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            ...report.daily.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.day),
                subtitle: Text("${item.orders} orders"),
                trailing: Text("LKR ${item.amount.toStringAsFixed(0)}"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
