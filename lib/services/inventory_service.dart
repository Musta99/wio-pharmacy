import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/drug.dart';
import 'package:wio_pharmacy/models/inventory_alert.dart';

class InventoryServiceException implements Exception {
  final String message;
  InventoryServiceException(this.message);
}

class InventoryService {
  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw InventoryServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Uri get _base =>
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/inventory');

  Future<List<Drug>> list() async {
    final res = await http.get(_base, headers: await _headers());
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw InventoryServiceException(
        payload['error'] as String? ?? 'Failed to load inventory',
      );
    }
    final list = payload['data'] as List<dynamic>? ?? [];
    return list.map((e) => Drug.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Drug> create(Drug drug) async {
    final res = await http.post(
      _base,
      headers: await _headers(),
      body: jsonEncode(drug.toJson(includeId: false)),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw InventoryServiceException(
        payload['error'] as String? ?? 'Failed to add item',
      );
    }
    return Drug.fromJson(payload['drug'] as Map<String, dynamic>);
  }

  Future<Drug> update(String id, Map<String, dynamic> patch) async {
    final res = await http.patch(
      _base,
      headers: await _headers(),
      body: jsonEncode({'id': id, ...patch}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw InventoryServiceException(
        payload['error'] as String? ?? 'Failed to update item',
      );
    }
    return Drug.fromJson(payload['drug'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final res = await http.delete(
      _base.replace(queryParameters: {'id': id}),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw InventoryServiceException(
        payload['error'] as String? ?? 'Failed to delete item',
      );
    }
  }

  // Add this method to the existing InventoryService class:
  Future<List<ReorderSuggestion>> getReorderSuggestions() async {
    final res = await http.get(
      _base.replace(queryParameters: {'view': 'reorder'}),
      headers: await _headers(),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || payload['success'] != true) {
      throw InventoryServiceException(
        payload['error'] as String? ?? 'Failed to load reorder suggestions',
      );
    }
    final list = payload['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ReorderSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
