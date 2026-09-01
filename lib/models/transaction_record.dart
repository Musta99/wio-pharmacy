// enum SettlementStatus { hold, settled, withdrawn }

// extension SettlementStatusX on SettlementStatus {
//   static SettlementStatus fromString(String s) {
//     switch (s) {
//       case 'HOLD':
//         return SettlementStatus.hold;
//       case 'WITHDRAWN':
//         return SettlementStatus.withdrawn;
//       case 'SETTLED':
//       default:
//         return SettlementStatus.settled;
//     }
//   }

//   String get label {
//     switch (this) {
//       case SettlementStatus.hold:
//         return 'HOLD';
//       case SettlementStatus.settled:
//         return 'SETTLED';
//       case SettlementStatus.withdrawn:
//         return 'WITHDRAWN';
//     }
//   }
// }

// class TransactionRecord {
//   final String id;
//   final String orderId;
//   final String timestamp;
//   final double totalAmount;
//   final double platformFee;
//   final double vendorEarning;
//   final SettlementStatus status;
//   final String pharmacyId;

//   TransactionRecord({
//     required this.id,
//     required this.orderId,
//     required this.timestamp,
//     required this.totalAmount,
//     required this.platformFee,
//     required this.vendorEarning,
//     required this.status,
//     required this.pharmacyId,
//   });

//   factory TransactionRecord.fromJson(Map<String, dynamic> json) =>
//       TransactionRecord(
//         id: json['id'] as String? ?? '',
//         orderId: json['orderId'] as String? ?? '',
//         timestamp: json['timestamp'] as String? ?? '',
//         totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
//         platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0,
//         vendorEarning: (json['vendorEarning'] as num?)?.toDouble() ?? 0,
//         status: SettlementStatusX.fromString(
//           json['status'] as String? ?? 'SETTLED',
//         ),
//         pharmacyId: json['pharmacyId'] as String? ?? '',
//       );
// }

// ---------------------

enum SettlementStatus { hold, settled, withdrawn }

extension SettlementStatusX on SettlementStatus {
  static SettlementStatus fromString(String s) {
    switch (s) {
      case 'HOLD':
        return SettlementStatus.hold;
      case 'WITHDRAWN':
        return SettlementStatus.withdrawn;
      case 'SETTLED':
      default:
        return SettlementStatus.settled;
    }
  }

  String get label {
    switch (this) {
      case SettlementStatus.hold:
        return 'HOLD';
      case SettlementStatus.settled:
        return 'SETTLED';
      case SettlementStatus.withdrawn:
        return 'WITHDRAWN';
    }
  }
}

enum SettlementPaymentMethod { cod, online, unknown }

extension SettlementPaymentMethodX on SettlementPaymentMethod {
  static SettlementPaymentMethod fromString(String? s) {
    switch (s) {
      case 'cod':
        return SettlementPaymentMethod.cod;
      case 'online':
        return SettlementPaymentMethod.online;
      default:
        return SettlementPaymentMethod.unknown;
    }
  }

  String get label {
    switch (this) {
      case SettlementPaymentMethod.cod:
        return 'COD';
      case SettlementPaymentMethod.online:
        return 'ONLINE';
      case SettlementPaymentMethod.unknown:
        return '';
    }
  }
}

class TransactionRecord {
  final String id;
  final String orderId;
  final String timestamp;
  final double totalAmount;
  final double platformFee;

  /// What the vendor earned on the sale (total - platformFee) — a record of
  /// the sale itself, NOT the wallet movement. See [walletDelta].
  final double vendorEarning;
  final SettlementStatus status;
  final String pharmacyId;
  final SettlementPaymentMethod paymentMethod;

  /// Signed wallet movement: +vendorEarning on online payment (platform held
  /// the money, owes the pharmacy its share); -platformFee on COD (pharmacy
  /// took the cash at the door, owes the platform its commission).
  final double? walletDelta;

  TransactionRecord({
    required this.id,
    required this.orderId,
    required this.timestamp,
    required this.totalAmount,
    required this.platformFee,
    required this.vendorEarning,
    required this.status,
    required this.pharmacyId,
    required this.paymentMethod,
    this.walletDelta,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) =>
      TransactionRecord(
        id: json['id'] as String? ?? '',
        orderId: json['orderId'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0,
        vendorEarning: (json['vendorEarning'] as num?)?.toDouble() ?? 0,
        status: SettlementStatusX.fromString(
          json['status'] as String? ?? 'SETTLED',
        ),
        pharmacyId: json['pharmacyId'] as String? ?? '',
        paymentMethod: SettlementPaymentMethodX.fromString(
          json['paymentMethod'] as String?,
        ),
        walletDelta: (json['walletDelta'] as num?)?.toDouble(),
      );

  /// Convenience: the signed movement, falling back to +vendorEarning if the
  /// server hasn't populated walletDelta on an older record.
  double get effectiveWalletDelta => walletDelta ?? vendorEarning;
}
