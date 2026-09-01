import 'package:wio_pharmacy/models/payout_request.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/models/transaction_record.dart';

/// The `/api/vendor/wallet` payload, shared by Sales and Analytics —
/// mirrors web's `VendorWalletData` type.
class VendorWalletBundle {
  final PharmacyWallet wallet;
  final List<TransactionRecord> transactions;
  final MarketplaceConfig? config;
  final PayoutRequest? pendingPayout;

  VendorWalletBundle({
    required this.wallet,
    required this.transactions,
    this.config,
    this.pendingPayout,
  });

  factory VendorWalletBundle.empty() => VendorWalletBundle(
    wallet: PharmacyWallet(
      pharmacyId: '',
      currentBalance: 0,
      withdrawableBalance: 0,
      totalWithdrawn: 0,
    ),
    transactions: [],
    config: MarketplaceConfig(
      minPurchaseAmount: 100,
      platformFeePercentage: 10,
      payoutThresholdBdt: 1000,
    ),
    pendingPayout: null,
  );

  factory VendorWalletBundle.fromJson(Map<String, dynamic> json) {
    final wallet = PharmacyWallet.fromJson(json);
    final transactions =
        (json['transactions'] as List<dynamic>? ?? [])
            .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
    final config =
        json['config'] != null
            ? MarketplaceConfig.fromJson(json['config'] as Map<String, dynamic>)
            : null;
    final pendingPayoutJson = json['pendingPayout'] as Map<String, dynamic>?;
    final pendingPayout =
        pendingPayoutJson != null
            ? PayoutRequest.fromJson(pendingPayoutJson)
            : null;
    return VendorWalletBundle(
      wallet: wallet,
      transactions: transactions,
      config: config,
      pendingPayout: pendingPayout,
    );
  }
}
