class BusinessSettings {
  const BusinessSettings({
    required this.businessName,
    required this.address,
    required this.phone,
    this.email,
    this.ownerName,
    this.logoUrl,
  });

  final String businessName;
  final String address;
  final String phone;
  final String? email;
  final String? ownerName;
  final String? logoUrl;

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      businessName: json['businessName'] as String? ?? 'Ice Cream',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      ownerName: json['ownerName'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  static const fallback = BusinessSettings(
    businessName: 'Ice Cream',
    address: '',
    phone: '',
  );

  BusinessSettings copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? ownerName,
    String? logoUrl,
    bool clearLogo = false,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ownerName: ownerName ?? this.ownerName,
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
    );
  }
}
