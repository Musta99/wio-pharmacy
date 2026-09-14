import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/field_model.dart';

class FieldApiException implements Exception {
  final String message;
  const FieldApiException(this.message);
  @override
  String toString() => message;
}

class FieldDispatchBoard {
  final List<FieldWorker> workers;
  final List<BoardShift> shifts;
  const FieldDispatchBoard({required this.workers, required this.shifts});
}

class StartShiftResult {
  final PublicFieldShift shift;
  final String? token;
  final Map<String, String> deliveryCodes;
  const StartShiftResult({
    required this.shift,
    this.token,
    this.deliveryCodes = const {},
  });
}

class FieldApiService {
  FieldApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri get _base =>
      Uri.parse('${ApiConstants.backendBaseUrl}/api/field/dispatch');

  Future<Map<String, String>> _authHeaders() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw const FieldApiException('Not authenticated');
    return {'Authorization': auth, 'Content-Type': 'application/json'};
  }

  /// Additive to the dashboard — a failed load returns an empty board
  /// rather than throwing, same as the web version's silent-catch `load()`.
  Future<FieldDispatchBoard> fetchBoard() async {
    try {
      final headers = await _authHeaders();
      final res = await _client.get(_base, headers: headers);
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || decoded['success'] != true) {
        return const FieldDispatchBoard(workers: [], shifts: []);
      }
      return FieldDispatchBoard(
        workers:
            (decoded['workers'] as List<dynamic>? ?? [])
                .map((e) => FieldWorker.fromJson(e as Map<String, dynamic>))
                .toList(),
        shifts:
            (decoded['shifts'] as List<dynamic>? ?? [])
                .map((e) => BoardShift.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
    } catch (_) {
      return const FieldDispatchBoard(workers: [], shifts: []);
    }
  }

  Future<StartShiftResult> startShift({
    required String workerId,
    required String authMethod, // 'otp' | 'token'
    required List<Map<String, dynamic>> stops,
  }) async {
    final headers = await _authHeaders();
    final res = await _client.post(
      _base,
      headers: headers,
      body: jsonEncode({
        'action': 'startShift',
        'workerId': workerId,
        'authMethod': authMethod,
        'stops': stops,
      }),
    );
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final ok =
        (res.statusCode == 200 || res.statusCode == 201) &&
        decoded['success'] == true;
    if (!ok) {
      throw FieldApiException(
        decoded['error'] as String? ?? 'Could not start the shift.',
      );
    }
    final codesRaw = decoded['deliveryCodes'] as Map<String, dynamic>? ?? {};
    return StartShiftResult(
      shift: PublicFieldShift.fromJson(
        decoded['shift'] as Map<String, dynamic>,
      ),
      token: decoded['token'] as String?,
      deliveryCodes: codesRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<FieldReconciliation?> endShift(
    String shiftId, {
    bool revoke = false,
  }) async {
    final headers = await _authHeaders();
    final res = await _client.post(
      _base,
      headers: headers,
      body: jsonEncode({
        'action': 'endShift',
        'shiftId': shiftId,
        if (revoke) 'revoke': true,
      }),
    );
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded['success'] != true) {
      throw FieldApiException(
        decoded['error'] as String? ?? 'Could not end the shift.',
      );
    }
    return decoded['reconciliation'] != null
        ? FieldReconciliation.fromJson(
          decoded['reconciliation'] as Map<String, dynamic>,
        )
        : null;
  }
}
