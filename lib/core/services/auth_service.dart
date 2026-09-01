import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/core/constants/api_constants.dart'; // adjust path to wherever you put this

class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});
}

class PharmacyAuthResult {
  final String uid;
  final String email;
  final String role;

  PharmacyAuthResult({
    required this.uid,
    required this.email,
    required this.role,
  });
}

class AuthService {
  Future<PharmacyAuthResult> loginPharmacy({
    required String email,
    required String password,
  }) {
    return _signIn(email: email, password: password, expectedRole: 'pharmacy');
  }

  Future<PharmacyAuthResult> _signIn({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    // Step 1: authenticate directly against Identity Toolkit
    final identityResponse = await http.post(
      Uri.parse(ApiConstants.identityToolkitSignInUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final identityBody =
        jsonDecode(identityResponse.body) as Map<String, dynamic>;

    if (identityResponse.statusCode != 200) {
      final message = identityBody['error']?['message'] as String?;
      throw AuthException(_mapIdentityError(message), code: message);
    }

    final idToken = identityBody['idToken'] as String?;
    final refreshToken = identityBody['refreshToken'] as String?;
    final uid = identityBody['localId'] as String?;
    final expiresIn =
        int.tryParse(identityBody['expiresIn']?.toString() ?? '') ?? 3600;

    if (idToken == null || refreshToken == null || uid == null) {
      throw AuthException('Unable to complete sign in');
    }

    // Step 2: verify + resolve role via your backend
    final signinResponse = await http.post(
      Uri.parse(ApiConstants.backendSigninUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'expectedRole': expectedRole}),
    );

    final signinBody = jsonDecode(signinResponse.body) as Map<String, dynamic>;

    if (signinResponse.statusCode != 200 || signinBody['success'] != true) {
      throw AuthException(
        signinBody['error'] as String? ?? 'Sign in failed',
        code: signinBody['code'] as String?,
      );
    }

    final role = signinBody['role'] as String;
    final resolvedEmail = signinBody['email'] as String? ?? email;

    await TokenService.instance.saveSession(
      idToken: idToken,
      refreshToken: refreshToken,
      uid: uid,
      email: resolvedEmail,
      role: role,
      expiresInSeconds: expiresIn,
    );

    return PharmacyAuthResult(uid: uid, email: resolvedEmail, role: role);
  }

  String _mapIdentityError(String? message) {
    switch (message) {
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'EMAIL_NOT_FOUND':
        return 'Invalid email or password';
      case 'USER_DISABLED':
        return 'This account has been disabled';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Too many login attempts. Please try again later';
      case 'INVALID_EMAIL':
        return 'Invalid email address';
      default:
        return 'Sign in failed';
    }
  }

  Future<void> logout() async {
    await TokenService.instance.clear();
  }
}
