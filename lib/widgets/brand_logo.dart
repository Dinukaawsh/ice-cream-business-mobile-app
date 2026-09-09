import "package:flutter/material.dart";

import "../config/brand.dart";

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 54,
    this.radius,
  });

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.24),
      child: Image.asset(
        Brand.logoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
