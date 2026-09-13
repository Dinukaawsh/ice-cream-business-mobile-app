import "package:flutter/material.dart";

import "../models/product.dart";
import "../services/api_service.dart";
import "../widgets/app_chrome.dart";
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
  var _showHidden = false;

  List<ProductItem> get _visibleProducts => _showHidden
      ? _products
      : _products.where((product) => product.isActive).toList();

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

  Future<void> _setActive(ProductItem product, {required bool enable}) async {
    final ok = await showConfirmDialog(
      context,
      title: enable ? "Enable product?" : "Disable product?",
      message: enable
          ? "Put ${product.name} back on sale?"
          : "Hide ${product.name} from new sales? Past bills will still show it as no longer available.",
      confirmLabel: enable ? "Enable" : "Disable",
      isDanger: !enable,
    );
    if (!ok) return;
    try {
      final message = await widget.api.setProductActive(
        id: product.id,
        isActive: enable,
      );
      if (!mounted) return;
      showSuccessToast(context, message);
      await _load();
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  Future<void> _delete(ProductItem product) async {
    final ok = await showConfirmDialog(
      context,
      title: "Delete product?",
      message:
          "Remove ${product.name} from the product list? Past bills will still show it as no longer available.",
      confirmLabel: "Delete",
      isDanger: true,
    );
    if (!ok) return;
    try {
      final message = await widget.api.deleteProduct(id: product.id);
      if (!mounted) return;
      showSuccessToast(context, message);
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
    return AppPage(
      title: "Products",
      actions: [
        IconButton(
          tooltip: _showHidden ? "Hide disabled" : "Show disabled",
          onPressed: () => setState(() => _showHidden = !_showHidden),
          icon: Icon(
            _showHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AuthColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add product"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _visibleProducts.isEmpty
                  ? AppEmptyState(
                      icon: Icons.icecream_outlined,
                      title: _showHidden
                          ? "No disabled products"
                          : "No products yet",
                      message:
                          "Add scoops, cones, and price sizes like Single, Double, or Pint.",
                      actionLabel: "Add your first product",
                      onAction: () => _openForm(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _visibleProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = _visibleProducts[index];
                        final prices = product.variants
                            .map((item) => item.price)
                            .toList();
                        final priceLabel = prices.isEmpty
                            ? "No sizes"
                            : prices.length == 1
                                ? "LKR ${prices.first.toStringAsFixed(0)}"
                                : "LKR ${prices.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)} – ${prices.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}";

                        return AppSurfaceCard(
                          onTap: () => _openForm(product: product),
                          child: Row(
                            children: [
                              AppIconBadge(
                                icon: Icons.icecream_rounded,
                                muted: !product.isActive,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AuthColors.ink,
                                      ),
                                    ),
                                    Text(
                                      "${product.flavor}${product.categoryName != null ? " · ${product.categoryName}" : ""}",
                                      style: const TextStyle(
                                        color: AuthColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        AppStatusChip(label: priceLabel),
                                        AppStatusChip(
                                          label:
                                              "${product.variants.length} size${product.variants.length == 1 ? "" : "s"}",
                                        ),
                                        if (!product.isActive)
                                          const AppStatusChip(
                                            label: "Disabled",
                                            tone: AppChipTone.danger,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (product.isActive)
                                IconButton(
                                  tooltip: "Disable",
                                  onPressed: () =>
                                      _setActive(product, enable: false),
                                  icon: const Icon(
                                    Icons.block,
                                    color: Color(0xFFB45309),
                                  ),
                                )
                              else ...[
                                IconButton(
                                  tooltip: "Enable",
                                  onPressed: () =>
                                      _setActive(product, enable: true),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                IconButton(
                                  tooltip: "Delete",
                                  onPressed: () => _delete(product),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
