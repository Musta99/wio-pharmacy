enum OrderStatus {
  pending,
  processing,
  quoted,
  outForDelivery,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  static OrderStatus fromString(String s) {
    switch (s) {
      case 'Pending':
        return OrderStatus.pending;
      case 'Processing':
        return OrderStatus.processing;
      case 'Quoted':
        return OrderStatus.quoted;
      case 'Out for Delivery':
        return OrderStatus.outForDelivery;
      case 'Completed':
        return OrderStatus.completed;
      case 'Cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.quoted:
        return 'Quoted';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItem {
  final String? medId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? expiryDate;

  OrderItem({
    this.medId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.expiryDate,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    medId: json['medId'] as String?,
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    expiryDate: json['expiryDate'] as String?,
  );
}

class DeliveryLocation {
  final double lat;
  final double lng;
  final int progress;
  DeliveryLocation({
    required this.lat,
    required this.lng,
    required this.progress,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) =>
      DeliveryLocation(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        progress: (json['progress'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'progress': progress,
  };
}

/// Why a delivery attempt did not succeed. Mirrors the web's
/// `FieldFailureReason` / `FAILED_REASON_LABEL`.
///
/// ⚠️ Inferred from the web dashboard's usage of `order.delivery.attempts`
/// — the exact attempt-object shape from your backend hasn't been
/// confirmed. If it differs (extra fields, different key names), only this
/// class and `DeliveryAttempt` need to change.
enum DeliveryFailureReason {
  notHome('not_home', 'Nobody home'),
  refused('refused', 'Patient refused the order'),
  wrongAddress('wrong_address', 'Wrong address'),
  unreachable('unreachable', 'Could not reach the patient'),
  paymentDeclined('payment_declined', 'Patient would not pay');

  final String value;
  final String label;
  const DeliveryFailureReason(this.value, this.label);

  static DeliveryFailureReason? fromJson(String? raw) {
    if (raw == null) return null;
    for (final r in DeliveryFailureReason.values) {
      if (r.value == raw) return r;
    }
    return null;
  }
}

class DeliveryAttempt {
  final DeliveryFailureReason? reason;
  final String? rawReason;
  final String? note;

  const DeliveryAttempt({this.reason, this.rawReason, this.note});

  factory DeliveryAttempt.fromJson(Map<String, dynamic> json) =>
      DeliveryAttempt(
        reason: DeliveryFailureReason.fromJson(json['reason'] as String?),
        rawReason: json['reason'] as String?,
        note: json['note'] as String?,
      );

  /// Falls back to the raw server string for a reason code this enum
  /// doesn't yet know, same as the web's `FAILED_REASON_LABEL[last.reason]
  /// ?? last.reason`.
  String get label => reason?.label ?? rawReason ?? 'failed';
}

class DeliveryInfo {
  final String? riderName;
  final String? riderPhone;
  final String? dispatchedAt;
  final String? deliveredAt;
  final DeliveryLocation? currentLocation;
  final List<DeliveryAttempt> attempts;

  DeliveryInfo({
    this.riderName,
    this.riderPhone,
    this.dispatchedAt,
    this.deliveredAt,
    this.currentLocation,
    this.attempts = const [],
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) => DeliveryInfo(
    riderName: json['riderName'] as String?,
    riderPhone: json['riderPhone'] as String?,
    dispatchedAt: json['dispatchedAt'] as String?,
    deliveredAt: json['deliveredAt'] as String?,
    currentLocation: json['currentLocation'] != null
        ? DeliveryLocation.fromJson(
            json['currentLocation'] as Map<String, dynamic>,
          )
        : null,
    attempts: (json['attempts'] as List<dynamic>? ?? [])
        .map((e) => DeliveryAttempt.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  DeliveryInfo copyWith({
    String? riderName,
    String? riderPhone,
    String? dispatchedAt,
    String? deliveredAt,
    DeliveryLocation? currentLocation,
    List<DeliveryAttempt>? attempts,
  }) => DeliveryInfo(
    riderName: riderName ?? this.riderName,
    riderPhone: riderPhone ?? this.riderPhone,
    dispatchedAt: dispatchedAt ?? this.dispatchedAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    currentLocation: currentLocation ?? this.currentLocation,
    attempts: attempts ?? this.attempts,
  );

  Map<String, dynamic> toJson() => {
    if (riderName != null) 'riderName': riderName,
    if (riderPhone != null) 'riderPhone': riderPhone,
    if (dispatchedAt != null) 'dispatchedAt': dispatchedAt,
    if (deliveredAt != null) 'deliveredAt': deliveredAt,
    if (currentLocation != null) 'currentLocation': currentLocation!.toJson(),
  };
}

class PharmaOrder {
  final String id;
  final String patientName;
  final String phone;
  final String address;
  final List<OrderItem> items;
  final OrderStatus status;
  final String paymentMethod;
  final String? prescriptionUrl;
  final double subtotal;
  final double tax;
  final double total;
  final String createdAt;
  final DeliveryInfo? delivery;
  final double? discount;
  final String? paymentStatus; // 'paid' | 'unpaid'
  final String? prescriptionStoragePath;
  final List<String>? unmatchedMeds;
  final String? pharmacistVerifiedBy;
  final String? pharmacistVerifiedAt;
  final String? pharmacistNotes;

  PharmaOrder({
    required this.id,
    required this.patientName,
    required this.phone,
    required this.address,
    required this.items,
    required this.status,
    required this.paymentMethod,
    this.prescriptionUrl,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.createdAt,
    this.delivery,
    this.discount,
    this.paymentStatus,
    this.prescriptionStoragePath,
    this.unmatchedMeds,
    this.pharmacistVerifiedBy,
    this.pharmacistVerifiedAt,
    this.pharmacistNotes,
  });

  factory PharmaOrder.fromJson(Map<String, dynamic> json) => PharmaOrder(
    id: json['id'] as String,
    patientName: json['patientName'] as String? ?? 'Unknown',
    phone: json['phone'] as String? ?? '',
    address: json['address'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    status: OrderStatusX.fromString(json['status'] as String? ?? 'Pending'),
    paymentMethod: json['paymentMethod'] as String? ?? '',
    prescriptionUrl: json['prescriptionUrl'] as String?,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    tax: (json['tax'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    delivery: json['delivery'] != null
        ? DeliveryInfo.fromJson(json['delivery'] as Map<String, dynamic>)
        : null,
    discount: (json['discount'] as num?)?.toDouble(),

    paymentStatus: json['paymentStatus'] as String?,
    prescriptionStoragePath: json['prescriptionStoragePath'] as String?,
    unmatchedMeds: (json['unmatchedMeds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    pharmacistVerifiedBy: json['pharmacistVerifiedBy'] as String?,
    pharmacistVerifiedAt: json['pharmacistVerifiedAt'] as String?,
    pharmacistNotes: json['pharmacistNotes'] as String?,
  );

  PharmaOrder copyWith({OrderStatus? status, DeliveryInfo? delivery}) =>
      PharmaOrder(
        id: id,
        patientName: patientName,
        phone: phone,
        address: address,
        items: items,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        prescriptionUrl: prescriptionUrl,
        subtotal: subtotal,
        tax: tax,
        total: total,
        createdAt: createdAt,
        delivery: delivery ?? this.delivery,
      );

  bool get needsRxVerification =>
      prescriptionUrl != null && pharmacistVerifiedAt == null;
}
