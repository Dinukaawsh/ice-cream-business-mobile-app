import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/product.dart";
import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, required this.api, this.product});

  final ApiService api;
  final ProductItem? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _VariantDraft {
  _VariantDraft({
    this.id,
    String label = "Regular",
    String price = "",
    String stock = "0",
  })  : label = TextEditingController(text: label),
        price = TextEditingController(text: price),
        stock = TextEditingController(text: stock);

  final int? id;
  final TextEditingController label;
  final TextEditingController price;
  final TextEditingController stock;

  void dispose() {
    label.dispose();
    price.dispose();
    stock.dispose();
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  final _flavor = TextEditingController();
  final _notes = TextEditingController();
  final _newCategory = TextEditingController();

  List<ProductCategory> _categories = [];
  int? _categoryId;
  var _isActive = true;
  var _loading = true;
  var _saving = false;
  final _variants = <_VariantDraft>[];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _flavor.text = product.flavor;
      _notes.text = product.notes ?? "";
      _categoryId = product.categoryId;
      _isActive = product.isActive;
      for (final variant in product.variants) {
        _variants.add(
          _VariantDraft(
            id: variant.id,
            label: variant.label,
            price: variant.price.toStringAsFixed(
              variant.price.truncateToDouble() == variant.price ? 0 : 2,
            ),
            stock: "${variant.stockQty}",
          ),
        );
      }
    }
    if (_variants.isEmpty) {
      _variants.add(_VariantDraft(label: "Single", price: "250", stock: "0"));
    }
    _boot();
  }

  Future<void> _boot() async {
    try {
      final categories = await widget.api.fetchCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
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
  void dispose() {
    _name.dispose();
    _flavor.dispose();
    _notes.dispose();
    _newCategory.dispose();
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _newCategory.text.trim();
    if (name.isEmpty) {
      showErrorToast(context, "Enter a category name");
      return;
    }
    try {
      final category = await widget.api.createCategory(name: name);
      if (!mounted) return;
      setState(() {
        _categories = [..._categories, category];
        _categoryId = category.id;
        _newCategory.clear();
      });
      showSuccessToast(context, "Category added");
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final flavor = _flavor.text.trim();
    if (name.isEmpty || flavor.isEmpty) {
      showErrorToast(context, "Name and flavor are required");
      return;
    }

    final variants = <ProductVariant>[];
    for (final draft in _variants) {
      final label = draft.label.text.trim();
      final price = double.tryParse(draft.price.text.trim());
      final stock = int.tryParse(draft.stock.text.trim()) ?? 0;
      if (label.isEmpty || price == null) {
        showErrorToast(context, "Each variant needs a label and valid price");
        return;
      }
      variants.add(
        ProductVariant(
          id: draft.id,
          label: label,
          price: price,
          stockQty: stock < 0 ? 0 : stock,
        ),
      );
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await widget.api.updateProduct(
          id: widget.product!.id,
          name: name,
          flavor: flavor,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          categoryId: _categoryId,
          variants: variants,
          isActive: _isActive,
        );
        if (!mounted) return;
        showSuccessToast(context, "Product updated");
      } else {
        await widget.api.createProduct(
          name: name,
          flavor: flavor,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          categoryId: _categoryId,
          variants: variants,
          isActive: _isActive,
        );
        if (!mounted) return;
        showSuccessToast(context, "Product created");
      }
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
    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _isEdit ? "Edit product" : "Add product",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AuthField(
                  controller: _name,
                  label: "Product name",
                  hint: "Vanilla scoop",
                  prefixIcon: Icons.icecream_outlined,
                ),
                const SizedBox(height: 14),
                AuthField(
                  controller: _flavor,
                  label: "Flavor",
                  hint: "Vanilla",
                  prefixIcon: Icons.spa_outlined,
                ),
                const SizedBox(height: 14),
                Text(
                  "Category",
                  style: authBodyStyle(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AuthColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: _categoryId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("No category"),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategory,
                        decoration: InputDecoration(
                          hintText: "New category",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _saving ? null : _addCategory,
                      child: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AuthField(
                  controller: _notes,
                  label: "Notes (optional)",
                  hint: "Allergen info, display tip…",
                  maxLines: 2,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Active / for sale"),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "Price variants",
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AuthColors.blueberry,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _variants.add(
                            _VariantDraft(label: "New size", price: "", stock: "0"),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add variant"),
                    ),
                  ],
                ),
                const Text(
                  "Example: Single, Double, Pint — each with its own price.",
                  style: TextStyle(color: AuthColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _variants.length; i++) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Variant ${i + 1}",
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            if (_variants.length > 1)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _variants.removeAt(i).dispose();
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                          ],
                        ),
                        TextField(
                          controller: _variants[i].label,
                          decoration: const InputDecoration(
                            labelText: "Label",
                            hintText: "Single",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _variants[i].price,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: "Price",
                                  hintText: "250",
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _variants[i].stock,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Stock",
                                  hintText: "0",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AuthPrimaryButton(
                  label: _isEdit ? "Save product" : "Create product",
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }
}
