import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/product.dart";
import "../models/sale.dart";
import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";

class _ReturnLine {
  _ReturnLine({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final ProductItem product;
  final ProductVariant variant;
  int quantity;
}

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<CustomerItem> _shops = [];
  List<ProductItem> _products = [];
  List<Map<String, dynamic>> _history = [];
  final _lines = <_ReturnLine>[];
  CustomerItem? _shop;
  final _notes = TextEditingController();
  var _loading = true;
  var _saving = false;
  var _restock = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final customers = await widget.api.fetchCustomers(type: "shop");
      final products = await widget.api.fetchProducts();
      final history = await widget.api.fetchReturns();
      if (!mounted) return;
      setState(() {
        _shops = customers;
        _products = products;
        _history = history;
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

  Future<void> _addLine() async {
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
          title: const Text("Return item"),
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
                        child: Text(item.name),
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
              ),
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
    final quantity = int.tryParse(qty.text.trim()) ?? 0;
    if (quantity <= 0) return;
    setState(() {
      _lines.add(
        _ReturnLine(product: product, variant: variant!, quantity: quantity),
      );
    });
  }

  Future<void> _submit() async {
    if (_shop == null) {
      showErrorToast(context, "Select a shop");
      return;
    }
    if (_lines.isEmpty) {
      showErrorToast(context, "Add return items");
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createReturn(
        customerId: _shop!.id,
        restock: _restock,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        items: _lines
            .map(
              (line) => {
                "productId": line.product.id,
                "variantId": line.variant.id,
                "quantity": line.quantity,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      showSuccessToast(context, "Return credited to shop");
      setState(() {
        _lines.clear();
        _notes.clear();
      });
      await _boot();
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
    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Returns",
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
                const Text(
                  "Shops return expired ice. Credit is deducted on their next sale.",
                  style: TextStyle(color: AuthColors.muted),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CustomerItem>(
                  // ignore: deprecated_member_use
                  value: _shop,
                  items: _shops
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _shop = value),
                  decoration: InputDecoration(
                    labelText: "Shop",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Restock returned items"),
                  value: _restock,
                  onChanged: (value) => setState(() => _restock = value),
                ),
                Row(
                  children: [
                    Text(
                      "Items",
                      style: GoogleFonts.fraunces(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                ..._lines.asMap().entries.map((entry) {
                  final line = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.product.name),
                    subtitle: Text(
                      "${line.variant.label} × ${line.quantity}",
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          setState(() => _lines.removeAt(entry.key)),
                      icon: const Icon(Icons.close, color: Color(0xFFB91C1C)),
                    ),
                  );
                }),
                AuthField(
                  controller: _notes,
                  label: "Notes",
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                AuthPrimaryButton(
                  label: "Record return",
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
                const SizedBox(height: 24),
                Text(
                  "Recent returns",
                  style: GoogleFonts.fraunces(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  const Text(
                    "No returns yet",
                    style: TextStyle(color: AuthColors.muted),
                  )
                else
                  ..._history.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item["customerName"]?.toString() ?? "Shop"),
                      subtitle: Text(
                        "LKR ${(item["totalAmount"] as num?)?.toStringAsFixed(0) ?? "0"}",
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
