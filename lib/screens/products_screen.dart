import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/product.dart";
import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/confirm_dialog.dart";
import "product_form_screen.dart";

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<ProductItem> _products = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await widget.api.fetchProducts();
      if (!mounted) return;
      setState(() => _products = products);
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

  Future<void> _openForm({ProductItem? product}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(api: widget.api, product: product),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete(ProductItem product) async {
    final ok = await showConfirmDialog(
      context,
      title: "Delete product?",
      message: "Remove ${product.name}? This cannot be undone.",
      confirmLabel: "Delete",
      isDanger: true,
    );
    if (!ok) return;
    try {
      await widget.api.deleteProduct(id: product.id);
      if (!mounted) return;
      showSuccessToast(context, "Product deleted");
      await _load();
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Products",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AuthColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("Add product"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _products.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.icecream_outlined,
                          size: 64,
                          color: AuthColors.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products yet",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AuthColors.blueberry,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Add scoops, cones, and price variants (Single, Double, Pint…).",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AuthColors.muted),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add),
                            label: const Text("Add your first product"),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final prices = product.variants
                            .map((item) => item.price)
                            .toList();
                        final priceLabel = prices.isEmpty
                            ? "No variants"
                            : prices.length == 1
                                ? "LKR ${prices.first.toStringAsFixed(0)}"
                                : "LKR ${prices.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)} – ${prices.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}";

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _openForm(product: product),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: Icon(
                                      Icons.icecream,
                                      color: product.isActive
                                          ? AuthColors.primaryDeep
                                          : AuthColors.muted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "${product.flavor}${product.categoryName != null ? " · ${product.categoryName}" : ""}",
                                          style: const TextStyle(
                                            color: AuthColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$priceLabel · ${product.variants.length} variant${product.variants.length == 1 ? "" : "s"}",
                                          style: TextStyle(
                                            color: AuthColors.primaryDeep,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (!product.isActive)
                                          const Text(
                                            "Inactive",
                                            style: TextStyle(
                                              color: Color(0xFFB91C1C),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _delete(product),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
