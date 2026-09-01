import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wio_pharmacy/core/constants/api_constants.dart';

/// Persists and serves the auth session (idToken, refreshToken, role, uid)
/// for use by every module in the app — not just the login screen.
class TokenService {
  TokenService._internal();
  static final TokenService instance = TokenService._internal();

  static const _kIdToken = 'wio_id_token';
  static const _kRefreshToken = 'wio_refresh_token';
  static const _kUid = 'wio_uid';
  static const _kEmail = 'wio_email';
  static const _kRole = 'wio_role';
  static const _kExpiryEpochMs = 'wio_token_expiry_ms';

  SharedPreferences? _prefs;

  // Prevents multiple concurrent requests from all firing their own refresh
  // call simultaneously (e.g. dashboard polling + a user-triggered request
  // landing in the same expiring-soon window). They all await the same Future.
  Future<bool>? _refreshInFlight;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveSession({
    required String idToken,
    required String refreshToken,
    required String uid,
    required String email,
    required String role,
    required int expiresInSeconds,
  }) async {
    final prefs = await _prefsInstance;
    final expiryEpochMs =
        DateTime.now()
            .add(Duration(seconds: expiresInSeconds))
            .millisecondsSinceEpoch;

    await Future.wait([
      prefs.setString(_kIdToken, idToken),
      prefs.setString(_kRefreshToken, refreshToken),
      prefs.setString(_kUid, uid),
      prefs.setString(_kEmail, email),
      prefs.setString(_kRole, role),
      prefs.setInt(_kExpiryEpochMs, expiryEpochMs),
    ]);
  }

  Future<String?> getRawIdToken() async {
    final prefs = await _prefsInstance;
    return prefs.getString(_kIdToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefsInstance;
    return prefs.getString(_kRefreshToken);
  }

  Future<String?> getUid() async {
    final prefs = await _prefsInstance;
    return prefs.getString(_kUid);
  }

  Future<String?> getEmail() async {
    final prefs = await _prefsInstance;
    return prefs.getString(_kEmail);
  }

  Future<String?> getRole() async {
    final prefs = await _prefsInstance;
    return prefs.getString(_kRole);
  }

  Future<bool> isTokenExpiringSoon({
    Duration buffer = const Duration(minutes: 2),
  }) async {
    final prefs = await _prefsInstance;
    final expiryEpochMs = prefs.getInt(_kExpiryEpochMs);
    if (expiryEpochMs == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryEpochMs);
    return DateTime.now().add(buffer).isAfter(expiry);
  }

  Future<bool> isLoggedIn() async {
    final token = await getRawIdToken();
    return token != null && token.isNotEmpty;
  }

  /// Exchanges the stored refresh token for a new idToken via Firebase's
  /// Secure Token API, and persists the result. Safe to call anytime — it's
  /// a no-op (returns true immediately) if the current idToken isn't close
  /// to expiring yet. Concurrent callers share a single in-flight request.
  Future<bool> refreshIfNeeded() async {
    if (!await isTokenExpiringSoon()) return true;
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.secureTokenRefreshUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
      );

      if (res.statusCode != 200) return false;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final newIdToken = body['id_token'] as String?;
      final newRefreshToken = body['refresh_token'] as String?;
      final expiresIn =
          int.tryParse(body['expires_in']?.toString() ?? '') ?? 3600;

      if (newIdToken == null || newRefreshToken == null) return false;

      final prefs = await _prefsInstance;
      final expiryEpochMs =
          DateTime.now()
              .add(Duration(seconds: expiresIn))
              .millisecondsSinceEpoch;

      await Future.wait([
        prefs.setString(_kIdToken, newIdToken),
        prefs.setString(_kRefreshToken, newRefreshToken),
        prefs.setInt(_kExpiryEpochMs, expiryEpochMs),
      ]);
      return true;
    } catch (_) {
      // Network error, malformed response, etc. — treat as refresh failure;
      // caller falls back to the expired-token / logged-out path.
      return false;
    }
  }

  /// Returns "Bearer <idToken>" ready to drop into an Authorization header.
  /// Other modules (appointments, dashboard, etc.) should call this rather
  /// than reading the raw token directly. Transparently refreshes the token
  /// first if it's expiring soon, so callers never have to think about it.
  Future<String?> getAuthorizationHeader() async {
    final refreshed = await refreshIfNeeded();
    final token = await getRawIdToken();
    if (token == null) return null;

    // Refresh was attempted (token was expiring) but failed, and the token
    // is now actually past expiry — the refresh token itself is likely dead.
    // Signal "not authenticated" so callers can route back to login instead
    // of sending a request we already know the backend will reject.
    if (!refreshed && await isTokenExpiringSoon(buffer: Duration.zero)) {
      return null;
    }
    return 'Bearer $token';
  }

  Future<void> clear() async {
    final prefs = await _prefsInstance;
    await Future.wait([
      prefs.remove(_kIdToken),
      prefs.remove(_kRefreshToken),
      prefs.remove(_kUid),
      prefs.remove(_kEmail),
      prefs.remove(_kRole),
      prefs.remove(_kExpiryEpochMs),
    ]);
  }

  @override
  String toString() => jsonEncode({'service': 'TokenService'});
}
