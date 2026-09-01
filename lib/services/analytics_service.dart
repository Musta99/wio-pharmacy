import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/payout_request.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/models/transaction_record.dart';

class AnalyticsServiceException implements Exception {
  final String message;
  AnalyticsServiceException(this.message);
  @override
  String toString() => message;
}

// class AnalyticsWalletBundle {
//   final PharmacyWallet wallet;
//   final List<TransactionRecord> ledger;
//   final MarketplaceConfig? config;
//   AnalyticsWalletBundle({
//     required this.wallet,
//     required this.ledger,
//     this.config,
//   });
// }

class AnalyticsWalletBundle {
  final PharmacyWallet wallet;
  final List<TransactionRecord> ledger;
  final MarketplaceConfig? config;
  final PayoutRequest? pendingPayout;
  AnalyticsWalletBundle({
    required this.wallet,
    required this.ledger,
    this.config,
    this.pendingPayout,
  });
}

class AnalyticsService {
  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw AnalyticsServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Future<List<PharmaOrder>> getOrders() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma?type=orders'),
      headers: await _headers(),
    );
    if (res.statusCode != 200)
      throw AnalyticsServiceException('Failed to load orders');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PharmaOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Drug>> getInventory() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/inventory'),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) return [];
    final list = payload['data'] as List<dynamic>? ?? [];
    return list.map((e) => Drug.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Mirrors web's loadWallet(): wallet fields are top-level in the response,
  /// alongside `transactions` and `config`.
  // Future<AnalyticsWalletBundle> getWalletBundle() async {
  //   final res = await http.get(
  //     Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/wallet'),
  //     headers: await _headers(),
  //   );
  //   final payload = jsonDecode(res.body) as Map<String, dynamic>?;
  //   if (res.statusCode != 200 || payload == null || payload['error'] != null) {
  //     // Web falls back to defaults silently on failure — mirror that.
  //     return AnalyticsWalletBundle(
  //       wallet: PharmacyWallet(
  //         pharmacyId: '',
  //         currentBalance: 0,
  //         withdrawableBalance: 0,
  //         totalWithdrawn: 0,
  //       ),
  //       ledger: [],
  //       config: MarketplaceConfig(
  //         minPurchaseAmount: 100,
  //         platformFeePercentage: 10,
  //         payoutThresholdBdt: 1000,
  //       ),
  //     );
  //   }
  //   final wallet = PharmacyWallet.fromJson(payload);
  //   final ledger =
  //       (payload['transactions'] as List<dynamic>? ?? [])
  //           .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
  //           .toList();
  //   final config =
  //       payload['config'] != null
  //           ? MarketplaceConfig.fromJson(
  //             payload['config'] as Map<String, dynamic>,
  //           )
  //           : null;
  //   return AnalyticsWalletBundle(
  //     wallet: wallet,
  //     ledger: ledger,
  //     config: config,
  //   );
  // }

  Future<AnalyticsWalletBundle> getWalletBundle() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/wallet'),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload == null || payload['error'] != null) {
      return AnalyticsWalletBundle(
        wallet: PharmacyWallet(
          pharmacyId: '',
          currentBalance: 0,
          withdrawableBalance: 0,
          totalWithdrawn: 0,
        ),
        ledger: [],
        config: MarketplaceConfig(
          minPurchaseAmount: 100,
          platformFeePercentage: 10,
          payoutThresholdBdt: 1000,
        ),
        pendingPayout: null,
      );
    }
    final wallet = PharmacyWallet.fromJson(payload);
    final ledger =
        (payload['transactions'] as List<dynamic>? ?? [])
            .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
    final config =
        payload['config'] != null
            ? MarketplaceConfig.fromJson(
              payload['config'] as Map<String, dynamic>,
            )
            : null;
    final pendingPayoutJson = payload['pendingPayout'] as Map<String, dynamic>?;
    final pendingPayout =
        pendingPayoutJson != null
            ? PayoutRequest.fromJson(pendingPayoutJson)
            : null;
    return AnalyticsWalletBundle(
      wallet: wallet,
      ledger: ledger,
      config: config,
      pendingPayout: pendingPayout,
    );
  }

  /// Returns (success, message)
  Future<(bool, String)> requestWithdraw(double amount) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/withdraw'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      return (
        false,
        payload?['error'] as String? ?? 'Failed to process withdrawal.',
      );
    }
    return (
      true,
      'The admin has been notified. Funds will be disbursed shortly.',
    );
  }
}
