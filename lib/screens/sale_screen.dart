import "dart:math" as math;

import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/product.dart";
import "../models/sale.dart";
import "../services/api_service.dart";
import "../widgets/app_chrome.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/confirm_dialog.dart";
import "sale_detail_screen.dart";

class _CartLine {
  _CartLine({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final ProductItem product;
  final ProductVariant variant;
  int quantity;

  double get lineTotal => variant.price * quantity;
}

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  List<ProductItem> _products = [];
  List<CustomerItem> _customers = [];
  final _cart = <_CartLine>[];
  final _walkInName = TextEditingController();
  final _paid = TextEditingController(text: "0");
  final _notes = TextEditingController();

  var _mode = "walkin"; // walkin | customer
  CustomerItem? _customer;
  var _loading = true;
  var _saving = false;
  var _applyCredit = true;

  @override
  void initState() {
    super.initState();
    _paid.addListener(() {
      if (mounted) setState(() {});
    });
    _boot();
  }

  @override
  void dispose() {
    _walkInName.dispose();
    _paid.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final products = await widget.api.fetchProducts();
      final customers = await widget.api.fetchCustomers();
      if (!mounted) return;
      setState(() {
        _products = products
            .where(
              (item) =>
                  item.isActive &&
                  item.variants.any((variant) => variant.isActive),
            )
            .toList();
        _customers = customers.where((item) => item.isActive).toList();
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

  double get _subtotal =>
      _cart.fold(0, (sum, line) => sum + line.lineTotal);

  double get _pastDue =>
      _mode == "customer" ? (_customer?.outstandingBalance ?? 0) : 0;

  double get _credit =>
      _mode == "customer" ? (_customer?.returnCredit ?? 0) : 0;

  double get _creditApplied {
    if (_mode != "customer" || !_applyCredit) return 0;
    return math.min(_credit, _pastDue + _subtotal);
  }

  double get _paidNow => double.tryParse(_paid.text.trim()) ?? 0;

  double get _remainingAfter => math.max(
        0,
        _pastDue + _subtotal - _creditApplied - _paidNow,
      );

  Future<void> _addItem() async {
    if (_products.isEmpty) {
      showErrorToast(context, "Add products first");
      return;
    }

    ProductItem product = _products.first;
    final initialVariants =
        product.variants.where((item) => item.isActive).toList();
    ProductVariant? variant =
        initialVariants.isEmpty ? null : initialVariants.first;
    final qty = TextEditingController(text: "1");

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Add item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ProductItem>(
                // ignore: deprecated_member_use
                value: product,
                items: _products
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text("${item.name} (${item.flavor})"),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() {
                    product = value;
                final active = value.variants
                    .where((item) => item.isActive)
                    .toList();
                variant = active.isEmpty ? null : active.first;
                  });
                },
                decoration: const InputDecoration(labelText: "Product"),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProductVariant>(
                // ignore: deprecated_member_use
                value: variant,
                items: product.variants
                    .where((item) => item.isActive)
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          "${item.label} · LKR ${item.price.toStringAsFixed(0)}",
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setLocal(() => variant = value),
                decoration: const InputDecoration(labelText: "Variant"),
              ),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Qty"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );

    if (ok != true || variant == null) return;
    if (!mounted) return;
    final quantity = int.tryParse(qty.text.trim()) ?? 0;
    if (quantity <= 0) {
      showErrorToast(context, "Enter a valid quantity");
      return;
    }

    setState(() {
      final existing = _cart.indexWhere(
        (line) =>
            line.product.id == product.id && line.variant.id == variant!.id,
      );
      if (existing >= 0) {
        _cart[existing].quantity += quantity;
      } else {
        _cart.add(
          _CartLine(product: product, variant: variant!, quantity: quantity),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) {
      showErrorToast(context, "Add at least one item");
      return;
    }
    if (_mode == "walkin" && _walkInName.text.trim().isEmpty) {
      showErrorToast(context, "Enter walk-in customer name");
      return;
    }
    if (_mode == "customer" && _customer == null) {
      showErrorToast(context, "Select a customer");
      return;
    }

    final paid = double.tryParse(_paid.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final sale = await widget.api.createSale(
        customerId: _mode == "customer" ? _customer!.id : null,
        walkInName: _mode == "walkin" ? _walkInName.text.trim() : null,
        paidAmount: paid,
        applyReturnCredit: _mode == "customer" && _applyCredit,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        items: _cart
            .map(
              (line) => {
                "productId": line.product.id,
                "variantId": line.variant.id!,
                "quantity": line.quantity,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      showSuccessToast(context, "Sale created");
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SaleDetailScreen(api: widget.api, saleId: sale.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _recordPayback() async {
    final customer = _customer;
    if (customer == null || _pastDue <= 0) return;
    final amount = _paidNow > 0 ? math.min(_paidNow, _pastDue) : _pastDue;
    final ok = await showConfirmDialog(
      context,
      title: "Record payback?",
      message:
          "Collect LKR ${amount.toStringAsFixed(0)} from ${customer.name} against unpaid bills? This is not a new sale.",
      confirmLabel: "Record payment",
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      final message = await widget.api.recordCustomerPayment(
        customerId: customer.id,
        amount: amount,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (!mounted) return;
      showSuccessToast(context, message);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = _credit;
    final due = _pastDue;

    return AppPage(
      title: "New sale",
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: "walkin", label: Text("Walk-in")),
                    ButtonSegment(value: "customer", label: Text("Customer")),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) =>
                      setState(() => _mode = value.first),
                ),
                const SizedBox(height: 14),
                if (_mode == "walkin")
                  AuthField(
                    controller: _walkInName,
                    label: "Customer name",
                    hint: "Person buying ice cream",
                    prefixIcon: Icons.person_outline,
                  )
                else ...[
                  DropdownButtonFormField<CustomerItem>(
                    // ignore: deprecated_member_use
                    value: _customer,
                    items: _customers
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.outstandingBalance > 0
                                  ? "${item.name} · due LKR ${item.outstandingBalance.toStringAsFixed(0)}"
                                  : "${item.name} (${item.type})",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _customer = value),
                    decoration: InputDecoration(
                      labelText: "Shop or person",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  if (_customer != null) ...[
                    const SizedBox(height: 10),
                    if (due > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Unpaid from past bills",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "LKR ${due.toStringAsFixed(0)} will be added to this bill. Collect it in Paid now, or record a payback without selling anything.",
                              style: const TextStyle(
                                color: Color(0xFF92400E),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        "No unpaid amount from past bills.",
                        style: TextStyle(color: AuthColors.muted, fontSize: 13),
                      ),
                    if (credit > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Return credit LKR ${credit.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: AuthColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (_customer!.type == "shop")
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Apply return credit"),
                        value: _applyCredit,
                        onChanged: (value) =>
                            setState(() => _applyCredit = value),
                      ),
                  ],
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      "Items",
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                if (_cart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "No items yet. Add a scoop to start the bill.",
                      style: TextStyle(color: AuthColors.muted),
                    ),
                  )
                else
                  ..._cart.asMap().entries.map((entry) {
                    final line = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppSurfaceCard(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        child: Row(
                          children: [
                            const AppIconBadge(icon: Icons.icecream_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${line.product.name} (${line.product.flavor})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AuthColors.ink,
                                    ),
                                  ),
                                  Text(
                                    "${line.variant.label} × ${line.quantity}",
                                    style: const TextStyle(
                                      color: AuthColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "LKR ${line.lineTotal.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AuthColors.primaryDeep,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _cart.removeAt(entry.key)),
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (due > 0)
                        _BillRow("Past unpaid", "LKR ${due.toStringAsFixed(0)}"),
                      _BillRow("Today's items", "LKR ${_subtotal.toStringAsFixed(0)}"),
                      if (_creditApplied > 0)
                        _BillRow(
                          "Return credit",
                          "- LKR ${_creditApplied.toStringAsFixed(0)}",
                        ),
                      _BillRow("Paid now", "LKR ${_paidNow.toStringAsFixed(0)}"),
                      const Divider(height: 18),
                      _BillRow(
                        "Still unpaid after this bill",
                        "LKR ${_remainingAfter.toStringAsFixed(0)}",
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AuthField(
                  controller: _paid,
                  label: "Paid now",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                AuthField(
                  controller: _notes,
                  label: "Notes (optional)",
                  maxLines: 2,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 20),
                if (due > 0 && _cart.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed: _saving ? null : _recordPayback,
                      child: Text(
                        "Record payback (no sale) · LKR ${(_paidNow > 0 ? math.min(_paidNow, due) : due).toStringAsFixed(0)}",
                      ),
                    ),
                  ),
                AuthPrimaryButton(
                  label: "Complete sale",
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AuthColors.ink : AuthColors.muted,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? const Color(0xFFB45309) : AuthColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
