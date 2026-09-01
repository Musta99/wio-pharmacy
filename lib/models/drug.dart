class DrugBatch {
  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final double purchaseCost;
  final String supplier;
  final String? invoiceNumber;

  DrugBatch({
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.purchaseCost,
    required this.supplier,
    this.invoiceNumber,
  });

  factory DrugBatch.fromJson(Map<String, dynamic> json) => DrugBatch(
    batchNumber: json['batchNumber'] as String? ?? '',
    expiryDate: json['expiryDate'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    purchaseCost: (json['purchaseCost'] as num?)?.toDouble() ?? 0,
    supplier: json['supplier'] as String? ?? '',
    invoiceNumber: json['invoiceNumber'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'expiryDate': expiryDate,
    'quantity': quantity,
    'purchaseCost': purchaseCost,
    'supplier': supplier,
    if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
  };
}

class DrugStock {
  final int current;
  final int min;
  final int max;
  DrugStock({required this.current, required this.min, required this.max});

  factory DrugStock.fromJson(Map<String, dynamic> json) => DrugStock(
    current: (json['current'] as num?)?.toInt() ?? 0,
    min: (json['min'] as num?)?.toInt() ?? 0,
    max: (json['max'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {'current': current, 'min': min, 'max': max};
}

class DrugStorage {
  final String zone;
  final String shelf;
  final String
  condition; // 'Room Temperature' | 'Cold Chain' | 'Controlled Substance'

  DrugStorage({
    required this.zone,
    required this.shelf,
    required this.condition,
  });

  factory DrugStorage.fromJson(Map<String, dynamic> json) => DrugStorage(
    zone: json['zone'] as String? ?? 'N/A',
    shelf: json['shelf'] as String? ?? 'N/A',
    condition: json['condition'] as String? ?? 'Room Temperature',
  );

  Map<String, dynamic> toJson() => {
    'zone': zone,
    'shelf': shelf,
    'condition': condition,
  };
}

class DrugPackaging {
  final int packSize;
  final String unitOfMeasure;
  DrugPackaging({required this.packSize, required this.unitOfMeasure});

  factory DrugPackaging.fromJson(Map<String, dynamic> json) => DrugPackaging(
    packSize: (json['packSize'] as num?)?.toInt() ?? 0,
    unitOfMeasure: json['unitOfMeasure'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'packSize': packSize,
    'unitOfMeasure': unitOfMeasure,
  };
}

class DrugPricing {
  final double costPrice;
  final double mrp;
  final double markupPercentage;
  final double vatPercentage;

  DrugPricing({
    required this.costPrice,
    required this.mrp,
    required this.markupPercentage,
    required this.vatPercentage,
  });

  factory DrugPricing.fromJson(Map<String, dynamic> json) => DrugPricing(
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
    markupPercentage: (json['markupPercentage'] as num?)?.toDouble() ?? 10,
    vatPercentage: (json['vatPercentage'] as num?)?.toDouble() ?? 5,
  );

  Map<String, dynamic> toJson() => {
    'costPrice': costPrice,
    'mrp': mrp,
    'markupPercentage': markupPercentage,
    'vatPercentage': vatPercentage,
  };
}

const kDrugForms = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment'];
const kDrugCategories = ['OTC', 'Rx', 'Scheduled'];
const kStorageConditions = [
  'Room Temperature',
  'Cold Chain',
  'Controlled Substance',
];
const kTherapeuticCategories = [
  'Analgesic',
  'Antibiotic',
  'Antiviral',
  'Cardiovascular',
  'Respiratory',
  'Gastrointestinal',
  'Neurological',
  'Dermatological',
  'Vitamins & Supplements',
  'Diabetic Care',
  'Other',
];

class Drug {
  final String id;
  final String sku;
  final String? barcode;
  final String brandName;
  final String genericName;
  final String form;
  final String strength;
  final String category;
  final String therapeuticCategory;
  final DrugStorage storage;
  final DrugPackaging packaging;
  final DrugPricing pricing;
  final DrugStock stock;
  final List<DrugBatch> batches;

  Drug({
    required this.id,
    required this.sku,
    this.barcode,
    required this.brandName,
    required this.genericName,
    required this.form,
    required this.strength,
    required this.category,
    required this.therapeuticCategory,
    required this.storage,
    required this.packaging,
    required this.pricing,
    required this.stock,
    required this.batches,
  });

  factory Drug.fromJson(Map<String, dynamic> json) => Drug(
    id: json['id'] as String,
    sku: json['sku'] as String? ?? '',
    barcode: json['barcode'] as String?,
    brandName: json['brandName'] as String? ?? '',
    genericName: json['genericName'] as String? ?? '',
    form: json['form'] as String? ?? 'Tablet',
    strength: json['strength'] as String? ?? '',
    category: json['category'] as String? ?? 'OTC',
    therapeuticCategory: json['therapeuticCategory'] as String? ?? 'Other',
    storage: DrugStorage.fromJson(
      json['storage'] as Map<String, dynamic>? ?? {},
    ),
    packaging: DrugPackaging.fromJson(
      json['packaging'] as Map<String, dynamic>? ?? {},
    ),
    pricing: DrugPricing.fromJson(
      json['pricing'] as Map<String, dynamic>? ?? {},
    ),
    stock: DrugStock.fromJson(json['stock'] as Map<String, dynamic>? ?? {}),
    batches:
        (json['batches'] as List<dynamic>? ?? [])
            .map((e) => DrugBatch.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toJson({bool includeId = true}) => {
    if (includeId) 'id': id,
    'sku': sku,
    if (barcode != null) 'barcode': barcode,
    'brandName': brandName,
    'genericName': genericName,
    'form': form,
    'strength': strength,
    'category': category,
    'therapeuticCategory': therapeuticCategory,
    'storage': storage.toJson(),
    'packaging': packaging.toJson(),
    'pricing': pricing.toJson(),
    'stock': stock.toJson(),
    'batches': batches.map((b) => b.toJson()).toList(),
  };
}
