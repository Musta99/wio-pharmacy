class ShipmentItem {
  final String drugId;
  final String drugName;
  final int quantity;
  final String batchNumber;
  final String expiryDate;
  final double unitCost;

  ShipmentItem({
    required this.drugId,
    required this.drugName,
    required this.quantity,
    required this.batchNumber,
    required this.expiryDate,
    required this.unitCost,
  });

  factory ShipmentItem.fromJson(Map<String, dynamic> json) => ShipmentItem(
    drugId: json['drugId'] as String? ?? '',
    drugName: json['drugName'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    batchNumber: json['batchNumber'] as String? ?? '',
    expiryDate: json['expiryDate'] as String? ?? '',
    unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'drugId': drugId,
    'drugName': drugName,
    'quantity': quantity,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate,
    'unitCost': unitCost,
  };

  ShipmentItem copyWith({
    String? drugId,
    String? drugName,
    int? quantity,
    String? batchNumber,
    String? expiryDate,
    double? unitCost,
  }) => ShipmentItem(
    drugId: drugId ?? this.drugId,
    drugName: drugName ?? this.drugName,
    quantity: quantity ?? this.quantity,
    batchNumber: batchNumber ?? this.batchNumber,
    expiryDate: expiryDate ?? this.expiryDate,
    unitCost: unitCost ?? this.unitCost,
  );
}

class Shipment {
  final String id;
  final String date;
  final String supplierName;
  final String invoiceNumber;
  final String status; // 'In Transit' | 'Received'
  final int itemCount;
  final List<ShipmentItem>? items;

  Shipment({
    required this.id,
    required this.date,
    required this.supplierName,
    required this.invoiceNumber,
    required this.status,
    required this.itemCount,
    this.items,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
    id: json['id'] as String,
    date: json['date'] as String? ?? '',
    supplierName: json['supplierName'] as String? ?? '',
    invoiceNumber: json['invoiceNumber'] as String? ?? '',
    status: json['status'] as String? ?? 'In Transit',
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    items:
        json['items'] != null
            ? (json['items'] as List<dynamic>)
                .map((e) => ShipmentItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
  );

  bool get canReceive => status != 'Received' && (items?.isNotEmpty ?? false);
}
