class MarketplaceConfig {
  final double minPurchaseAmount;
  final double platformFeePercentage;
  final double payoutThresholdBdt;

  MarketplaceConfig({
    required this.minPurchaseAmount,
    required this.platformFeePercentage,
    required this.payoutThresholdBdt,
  });

  factory MarketplaceConfig.fromJson(Map<String, dynamic> json) =>
      MarketplaceConfig(
        minPurchaseAmount: (json['minPurchaseAmount'] as num?)?.toDouble() ?? 0,
        platformFeePercentage:
            (json['platformFeePercentage'] as num?)?.toDouble() ?? 0,
        payoutThresholdBdt:
            (json['payoutThresholdBdt'] as num?)?.toDouble() ?? 0,
      );
}

class PharmacyWallet {
  final String pharmacyId;
  final double currentBalance;
  final double withdrawableBalance;
  final double totalWithdrawn;
  final MarketplaceConfig? config;
  // transactions omitted here since SalesScreen doesn't render them yet —
  // add a `List<LedgerEntry> transactions` later if/when you build a ledger view.

  PharmacyWallet({
    required this.pharmacyId,
    required this.currentBalance,
    required this.withdrawableBalance,
    required this.totalWithdrawn,
    this.config,
  });

  factory PharmacyWallet.fromJson(Map<String, dynamic> json) => PharmacyWallet(
    pharmacyId: json['pharmacyId'] as String? ?? '',
    currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
    withdrawableBalance: (json['withdrawableBalance'] as num?)?.toDouble() ?? 0,
    totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0,
    config:
        json['config'] != null
            ? MarketplaceConfig.fromJson(json['config'] as Map<String, dynamic>)
            : null,
  );
}

class PharmacyProfile {
  final String? id;
  final String name;
  final String tagline;
  final String description;
  final String email;
  final String phone;
  final String address;
  final String licenseNo;
  final String taxBin;
  final String logoUrl;

  PharmacyProfile({
    this.id,
    this.name = '',
    this.tagline = '',
    this.description = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.licenseNo = '',
    this.taxBin = '',
    this.logoUrl = '',
  });

  static final empty = PharmacyProfile();

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) =>
      PharmacyProfile(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        tagline: json['tagline'] as String? ?? '',
        description: json['description'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        licenseNo: json['licenseNo'] as String? ?? '',
        taxBin: json['taxBin'] as String? ?? '',
        logoUrl: json['logoUrl'] as String? ?? '',
      );

  /// Sent on PATCH — mirrors web's `body: JSON.stringify(formData)`.
  Map<String, dynamic> toJson() => {
    'name': name,
    'tagline': tagline,
    'description': description,
    'email': email,
    'phone': phone,
    'address': address,
    'licenseNo': licenseNo,
    'taxBin': taxBin,
    'logoUrl': logoUrl,
  };

  PharmacyProfile copyWith({
    String? name,
    String? tagline,
    String? description,
    String? email,
    String? phone,
    String? address,
    String? licenseNo,
    String? taxBin,
    String? logoUrl,
  }) => PharmacyProfile(
    id: id,
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    description: description ?? this.description,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    licenseNo: licenseNo ?? this.licenseNo,
    taxBin: taxBin ?? this.taxBin,
    logoUrl: logoUrl ?? this.logoUrl,
  );
}

// MarketplaceConfig / PharmacyWallet stay as before — unchanged.
