import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/product.dart";
import "../models/sale.dart";
import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
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
        _products = products.where((item) => item.isActive).toList();
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

  Future<void> _addItem() async {
    if (_products.isEmpty) {
      showErrorToast(context, "Add products first");
      return;
    }

    ProductItem product = _products.first;
    ProductVariant? variant =
        product.variants.isEmpty ? null : product.variants.first;
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
                    variant = value.variants.isEmpty
                        ? null
                        : value.variants.first;
                  });
                },
                decoration: const InputDecoration(labelText: "Product"),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProductVariant>(
                // ignore: deprecated_member_use
                value: variant,
                items: product.variants
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

  @override
  Widget build(BuildContext context) {
    final credit = _customer?.returnCredit ?? 0;
    final due = _customer?.outstandingBalance ?? 0;

    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "New sale",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
      ),
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
                              "${item.name} (${item.type})",
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
                    const SizedBox(height: 8),
                    Text(
                      "Due LKR ${due.toStringAsFixed(0)} · Return credit LKR ${credit.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: AuthColors.muted,
                        fontSize: 12,
                      ),
                    ),
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
                  const Text(
                    "No items yet",
                    style: TextStyle(color: AuthColors.muted),
                  )
                else
                  ..._cart.asMap().entries.map((entry) {
                    final line = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${line.product.name} (${line.product.flavor})",
                      ),
                      subtitle: Text(
                        "${line.variant.label} × ${line.quantity} = LKR ${line.lineTotal.toStringAsFixed(0)}",
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            setState(() => _cart.removeAt(entry.key)),
                        icon: const Icon(Icons.close, color: Color(0xFFB91C1C)),
                      ),
                    );
                  }),
                const Divider(),
                Text(
                  "Subtotal: LKR ${_subtotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
