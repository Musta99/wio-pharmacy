class ExpiryAlert {
  final String drugId;
  final String brandName;
  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final int daysUntilExpiry;

  ExpiryAlert({
    required this.drugId,
    required this.brandName,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.daysUntilExpiry,
  });
}

class ReorderSuggestion {
  final String drugId;
  final String brandName;
  final int currentStock;
  final int min;
  final int max;
  final double dailyVelocity;
  final int? daysOfStockLeft;
  final int suggestedQty;
  final String reason; // 'below-min' | 'low-velocity-runway'

  ReorderSuggestion({
    required this.drugId,
    required this.brandName,
    required this.currentStock,
    required this.min,
    required this.max,
    required this.dailyVelocity,
    required this.daysOfStockLeft,
    required this.suggestedQty,
    required this.reason,
  });

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) =>
      ReorderSuggestion(
        drugId: json['drugId'] as String? ?? '',
        brandName: json['brandName'] as String? ?? '',
        currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
        min: (json['min'] as num?)?.toInt() ?? 0,
        max: (json['max'] as num?)?.toInt() ?? 0,
        dailyVelocity: (json['dailyVelocity'] as num?)?.toDouble() ?? 0,
        daysOfStockLeft: (json['daysOfStockLeft'] as num?)?.toInt(),
        suggestedQty: (json['suggestedQty'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? 'below-min',
      );
}
