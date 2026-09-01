import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/pharmacy_staff.dart';

class StaffServiceException implements Exception {
  final String message;
  StaffServiceException(this.message);
  @override
  String toString() => message;
}

class StaffService {
  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw StaffServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Uri get _url => Uri.parse('${ApiConstants.backendBaseUrl}/api/pharma/staff');

  Future<List<PharmacyStaff>> list() async {
    final res = await http.get(_url, headers: await _headers());
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw StaffServiceException(
        payload?['error'] as String? ?? 'Failed to load staff',
      );
    }
    final list = payload!['staff'] as List<dynamic>? ?? [];
    return list
        .map((e) => PharmacyStaff.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String name,
    required String email,
    required String password,
    required PharmacyStaffRole subRole,
  }) async {
    final res = await http.post(
      _url,
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'subRole': subRole.apiValue,
      }),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw StaffServiceException(
        payload?['error'] as String? ?? "Couldn't add staff",
      );
    }
  }

  Future<void> toggleActive(String uid, bool active) async {
    final res = await http.patch(
      _url,
      headers: await _headers(),
      body: jsonEncode({'uid': uid, 'active': active}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw StaffServiceException(
        payload?['error'] as String? ?? 'Failed to update staff status',
      );
    }
  }

  Future<void> changeRole(String uid, PharmacyStaffRole subRole) async {
    final res = await http.patch(
      _url,
      headers: await _headers(),
      body: jsonEncode({'uid': uid, 'subRole': subRole.apiValue}),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw StaffServiceException(
        payload?['error'] as String? ?? 'Failed to update role',
      );
    }
  }
}
