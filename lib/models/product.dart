class ProductVariant {
  const ProductVariant({
    this.id,
    required this.label,
    required this.price,
    required this.stockQty,
    this.isActive = true,
  });

  final int? id;
  final String label;
  final double price;
  final int stockQty;
  final bool isActive;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int?,
      label: json['label'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stockQty: json['stockQty'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'label': label,
        'price': price,
        'stockQty': stockQty,
        'isActive': isActive,
      };
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.flavor,
    required this.variants,
    this.notes,
    this.categoryId,
    this.categoryName,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String flavor;
  final String? notes;
  final int? categoryId;
  final String? categoryName;
  final bool isActive;
  final List<ProductVariant> variants;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      flavor: json['flavor'] as String? ?? '',
      notes: json['notes'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((item) => ProductVariant.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}
