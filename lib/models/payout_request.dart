enum PayoutStatus { pending, approved, rejected }

extension PayoutStatusX on PayoutStatus {
  static PayoutStatus fromString(String s) {
    switch (s) {
      case 'APPROVED':
        return PayoutStatus.approved;
      case 'REJECTED':
        return PayoutStatus.rejected;
      case 'PENDING':
      default:
        return PayoutStatus.pending;
    }
  }
}

class PayoutRequest {
  final String id;
  final String pharmacyId;
  final double amount;
  final PayoutStatus status;
  final String timestamp;
  final String? decidedBy;
  final String? decidedAt;
  final String? paidAt;
  final String? transferReference;

  PayoutRequest({
    required this.id,
    required this.pharmacyId,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.decidedBy,
    this.decidedAt,
    this.paidAt,
    this.transferReference,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) => PayoutRequest(
    id: json['id'] as String? ?? '',
    pharmacyId: json['pharmacyId'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: PayoutStatusX.fromString(json['status'] as String? ?? 'PENDING'),
    timestamp: json['timestamp'] as String? ?? '',
    decidedBy: json['decidedBy'] as String?,
    decidedAt: json['decidedAt'] as String?,
    paidAt: json['paidAt'] as String?,
    transferReference: json['transferReference'] as String?,
  );
}
