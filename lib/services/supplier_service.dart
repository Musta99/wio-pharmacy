import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/shipment.dart';
import 'package:wio_pharmacy/models/supplier.dart';

class SupplierServiceException implements Exception {
  final String message;
  SupplierServiceException(this.message);
  @override
  String toString() => message;
}

class SupplierService {
  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw SupplierServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Uri get _suppliersUrl =>
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/suppliers');
  Uri get _shipmentsUrl =>
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/shipments');

  Future<(List<Supplier>, List<Shipment>)> load() async {
    final res = await http.get(_suppliersUrl, headers: await _headers());
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw SupplierServiceException(
        payload['error'] as String? ?? 'Failed to load suppliers',
      );
    }
    final data = payload['data'] as Map<String, dynamic>;
    final suppliers =
        (data['suppliers'] as List<dynamic>? ?? [])
            .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
            .toList();
    final shipments =
        (data['shipments'] as List<dynamic>? ?? [])
            .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
            .toList();
    return (suppliers, shipments);
  }

  Future<void> createSupplier(Supplier s) async {
    final res = await http.post(
      _suppliersUrl,
      headers: await _headers(),
      body: jsonEncode(s.toJson(includeId: false)),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw SupplierServiceException(
        payload['error'] as String? ?? 'Failed to add supplier',
      );
    }
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> patch) async {
    final res = await http.patch(
      _suppliersUrl,
      headers: await _headers(),
      body: jsonEncode({'id': id, ...patch}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw SupplierServiceException(
        payload['error'] as String? ?? 'Failed to update supplier',
      );
    }
  }

  Future<void> deleteSupplier(String id) async {
    final res = await http.delete(
      _suppliersUrl.replace(queryParameters: {'id': id}),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw SupplierServiceException(
        payload['error'] as String? ?? 'Failed to delete supplier',
      );
    }
  }

  Future<void> createShipment({
    required String supplierId,
    required String supplierName,
    required String invoiceNumber,
    String? date, // optional — server defaults to today if omitted
    required List<ShipmentItem> items,
  }) async {
    final res = await http.post(
      _shipmentsUrl, // NOTE: this now points to /api/pharmacy/shipments directly (see below)
      headers: await _headers(),
      body: jsonEncode({
        'supplierId': supplierId,
        'supplierName': supplierName,
        'invoiceNumber': invoiceNumber,
        if (date != null) 'date': date,
        'items': items.map((i) => i.toJson()).toList(),
      }),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw SupplierServiceException(
        payload['error'] as String? ?? "Couldn't create shipment",
      );
    }
  }

  /// Returns the number of items restocked, per the web handler's response shape.
  Future<int> receiveShipment(String shipmentId) async {
    final res = await http.patch(
      _shipmentsUrl,
      headers: await _headers(),
      body: jsonEncode({'shipmentId': shipmentId}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw SupplierServiceException(
        payload['error'] as String? ?? 'Receive failed',
      );
    }
    return (payload['restockedItems'] as num?)?.toInt() ?? 0;
  }
}
