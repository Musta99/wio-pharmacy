// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:wio_pharmacy/core/constants/api_constants.dart';
// import 'package:wio_pharmacy/core/services/token_services.dart';
// import 'package:wio_pharmacy/models/drug.dart';
// import 'package:wio_pharmacy/models/pharma_order.dart';

// class PharmacyServiceException implements Exception {
//   final String message;
//   PharmacyServiceException(this.message);
// }

// class PharmacyService {
//   Future<Map<String, String>> _headers() async {
//     final auth = await TokenService.instance.getAuthorizationHeader();
//     if (auth == null) throw PharmacyServiceException('Not authenticated');
//     return {'Content-Type': 'application/json', 'Authorization': auth};
//   }

//   Future<List<PharmaOrder>> getOrders() async {
//     final res = await http.get(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma?type=orders'),
//       headers: await _headers(),
//     );
//     if (res.statusCode != 200) {
//       throw PharmacyServiceException(
//         'Failed to load orders (${res.statusCode})',
//       );
//     }
//     final list = jsonDecode(res.body) as List<dynamic>;
//     return list
//         .map((e) => PharmaOrder.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   Future<void> patchOrder(String orderId, Map<String, dynamic> body) async {
//     final res = await http.patch(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma'),
//       headers: await _headers(),
//       body: jsonEncode({'orderId': orderId, ...body}),
//     );
//     if (res.statusCode != 200) {
//       throw PharmacyServiceException(
//         'Failed to update order (${res.statusCode})',
//       );
//     }
//   }

//   Future<List<Drug>> getInventory() async {
//     final res = await http.get(
//       Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/inventory'),
//       headers: await _headers(),
//     );
//     if (res.statusCode != 200) {
//       throw PharmacyServiceException(
//         'Failed to load inventory (${res.statusCode})',
//       );
//     }
//     final payload = jsonDecode(res.body) as Map<String, dynamic>;
//     if (payload['success'] != true) return [];
//     final list = payload['data'] as List<dynamic>? ?? [];
//     return list.map((e) => Drug.fromJson(e as Map<String, dynamic>)).toList();
//   }
// }

// ---------------------------------------------------------

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/pharma_order.dart';

class PharmacyServiceException implements Exception {
  final String message;

  /// Server-provided machine-readable code, when present — e.g.
  /// 'RX_NOT_VERIFIED', 'ORDER_UNPAID', 'ORDER_UNOWNED'. Null for generic
  /// errors (validation, network, auth) that don't carry a specific code.
  final String? code;

  /// True when the failure was an HTTP 409 — used to distinguish "this
  /// request is stale/contested" (claim races, illegal transitions) from a
  /// hard failure, even when no specific `code` is set.
  final bool isConflict;

  PharmacyServiceException(this.message, {this.code, this.isConflict = false});

  @override
  String toString() => message;
}

class PharmacyService {
  /// Pharmacist sign-off on an Rx order. Server-idempotent (re-verifying an
  /// already-verified order returns success with alreadyVerified: true).
  Future<PharmaOrder> verifyRx(String orderId, {String? notes}) async {
    final res = await http.patch(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma'),
      headers: await _headers(),
      body: jsonEncode({
        'orderId': orderId,
        'action': 'verify-rx',
        if (notes != null && notes.isNotEmpty) 'pharmacistNotes': notes,
      }),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      final message =
          payload?['error'] as String? ?? 'Failed to verify prescription';
      throw PharmacyServiceException(
        message,
        code: payload?['code'] as String?,
        isConflict: res.statusCode == 409,
      );
    }
    return PharmaOrder.fromJson(payload!['order'] as Map<String, dynamic>);
  }

  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw PharmacyServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Future<List<PharmaOrder>> getOrders() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma?type=orders'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw PharmacyServiceException(
        'Failed to load orders (${res.statusCode})',
      );
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PharmaOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generic PATCH — throws PharmacyServiceException with code/isConflict
  /// populated from the server response, so callers can branch on the exact
  /// failure (claim race, Rx not verified, unpaid, unowned) rather than just
  /// showing raw text.
  Future<PharmaOrder> patchOrder(
    String orderId,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma'),
      headers: await _headers(),
      body: jsonEncode({'orderId': orderId, ...body}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;

    if (res.statusCode != 200 || payload?['success'] != true) {
      final message =
          payload?['error'] as String? ??
          'Failed to update order (${res.statusCode})';
      final code = payload?['code'] as String?;
      throw PharmacyServiceException(
        message,
        code: code,
        isConflict: res.statusCode == 409,
      );
    }
    return PharmaOrder.fromJson(payload!['order'] as Map<String, dynamic>);
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
}
