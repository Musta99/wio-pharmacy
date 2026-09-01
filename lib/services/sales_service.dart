// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:wio_pharmacy/core/constants/api_constants.dart';
// import 'package:wio_pharmacy/core/services/token_services.dart';
// import 'package:wio_pharmacy/models/pharma_order.dart';
// import 'package:wio_pharmacy/models/pharmacy_wallet.dart';

// class SalesServiceException implements Exception {
//   final String message;
//   SalesServiceException(this.message);

//   @override
//   String toString() => message;
// }

// class SalesService {
//   Future<Map<String, String>> _headers() async {
//     final auth = await TokenService.instance.getAuthorizationHeader();
//     if (auth == null) throw SalesServiceException('Not authenticated');
//     return {'Content-Type': 'application/json', 'Authorization': auth};
//   }

//   Future<List<PharmaOrder>> getOrders() async {
//     final res = await http.get(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma?type=orders'),
//       headers: await _headers(),
//     );
//     if (res.statusCode != 200) {
//       // TEMP debug — remove once resolved
//       print('getOrders failed: ${res.statusCode} — ${res.body}');
//       throw SalesServiceException('Failed to load orders (${res.statusCode})');
//     }
//     final list = jsonDecode(res.body) as List<dynamic>;
//     return list
//         .map((e) => PharmaOrder.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   Future<PharmacyWallet?> getWallet() async {
//     final res = await http.get(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/wallet'),
//       headers: await _headers(),
//     );
//     if (res.statusCode != 200) return null;
//     return PharmacyWallet.fromJson(
//       jsonDecode(res.body) as Map<String, dynamic>,
//     );
//   }

//   Future<PharmacyProfile?> getProfile() async {
//     final res = await http.get(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/profile'),
//       headers: await _headers(),
//     );
//     final payload = jsonDecode(res.body) as Map<String, dynamic>?;
//     if (res.statusCode != 200 || payload?['data']?['profile'] == null)
//       return null;
//     return PharmacyProfile.fromJson(
//       payload!['data']['profile'] as Map<String, dynamic>,
//     );
//   }

//   Future<(PharmacyProfile?, bool)> getProfileWithOwnership() async {
//     final res = await http.get(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/profile'),
//       headers: await _headers(),
//     );
//     final payload = jsonDecode(res.body) as Map<String, dynamic>?;
//     if (res.statusCode != 200 || payload?['data']?['profile'] == null) {
//       return (
//         null,
//         true,
//       ); // default to owner-safe (matches web's `isOwner=true` default)
//     }
//     final data = payload!['data'] as Map<String, dynamic>;
//     final profile = PharmacyProfile.fromJson(
//       data['profile'] as Map<String, dynamic>,
//     );
//     final subRole = data['subRole'];
//     return (profile, subRole == null); // isOwner = !subRole, same as web
//   }

//   /// Returns (success, message)
//   Future<(bool, String)> requestPayout(double amount) async {
//     final res = await http.post(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/withdraw'),
//       headers: await _headers(),
//       body: jsonEncode({'amount': amount}),
//     );
//     final payload = jsonDecode(res.body) as Map<String, dynamic>?;
//     if (res.statusCode != 200 || payload?['success'] != true) {
//       return (false, payload?['error'] as String? ?? 'Payout request failed');
//     }
//     return (true, payload?['message'] as String? ?? 'Payout requested');
//   }
// }

// -------------------------------------------------

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/models/vendor_wallet_bundle.dart';

class SalesServiceException implements Exception {
  final String message;
  SalesServiceException(this.message);
  @override
  String toString() => message;
}

class SalesService {
  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw SalesServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Future<List<PharmaOrder>> getOrders() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma?type=orders'),
      headers: await _headers(),
    );
    if (res.statusCode != 200)
      throw SalesServiceException('Failed to load orders (${res.statusCode})');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PharmaOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the full wallet bundle — wallet + transactions + config +
  /// pendingPayout — mirroring web's VendorWalletData shape. Falls back to
  /// an empty bundle on failure rather than throwing, matching web's
  /// "keep defaults" behavior for the wallet card.
  Future<VendorWalletBundle> getWalletBundle() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/wallet'),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload == null || payload['error'] != null) {
      return VendorWalletBundle.empty();
    }
    return VendorWalletBundle.fromJson(payload);
  }

  /// Returns (profile, isOwner) — subRole is a sibling field of profile in the
  /// response, not part of it, so we resolve isOwner here rather than on the model.
  Future<(PharmacyProfile?, bool)> getProfileWithOwnership() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/profile'),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['data']?['profile'] == null) {
      return (
        null,
        true,
      ); // default to owner-safe (matches web's `isOwner=true` default)
    }
    final data = payload!['data'] as Map<String, dynamic>;
    final profile = PharmacyProfile.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
    final subRole = data['subRole'];
    return (profile, subRole == null); // isOwner = !subRole, same as web
  }

  /// Returns (success, message)
  Future<(bool, String)> requestPayout(double amount) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/vendor/withdraw'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      return (false, payload?['error'] as String? ?? 'Payout request failed');
    }
    return (true, payload?['message'] as String? ?? 'Payout requested');
  }
}
