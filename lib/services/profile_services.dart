import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wio_pharmacy/core/constants/api_constants.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';

class ProfileServiceException implements Exception {
  final String message;
  ProfileServiceException(this.message);
  @override
  String toString() => message;
}

class ProfileService {
  Future<Map<String, String>> _headers() async {
    final auth = await TokenService.instance.getAuthorizationHeader();
    if (auth == null) throw ProfileServiceException('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': auth};
  }

  Future<String?> _authHeaderOnly() =>
      TokenService.instance.getAuthorizationHeader();

  Uri get _profileUrl =>
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/profile');
  Uri get _photoUrl =>
      Uri.parse('${ApiConstants.backendBaseUrl}/api/pharmacy/profile/photo');

  /// Returns (profile, isOwner) — subRole is a sibling of profile in the response.
  Future<(PharmacyProfile, bool)> getProfile() async {
    final res = await http.get(_profileUrl, headers: await _headers());
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw ProfileServiceException(
        payload?['error'] as String? ?? 'Failed to load pharmacy profile',
      );
    }
    final data = payload!['data'] as Map<String, dynamic>;
    final profileJson = data['profile'] as Map<String, dynamic>?;
    final profile =
        profileJson != null
            ? PharmacyProfile.fromJson(profileJson)
            : PharmacyProfile.empty;
    final isOwner = data['subRole'] == null;
    return (profile, isOwner);
  }

  Future<void> updateProfile(PharmacyProfile profile) async {
    final res = await http.patch(
      _profileUrl,
      headers: await _headers(),
      body: jsonEncode(profile.toJson()),
    );
    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw ProfileServiceException(
        payload?['error'] as String? ?? 'Could not save your profile.',
      );
    }
  }

  /// Uploads a logo image; returns the new logoUrl on success.
  Future<String> uploadLogo(File file) async {
    final auth = await _authHeaderOnly();
    if (auth == null) throw ProfileServiceException('Not authenticated');

    final request =
        http.MultipartRequest('POST', _photoUrl)
          ..headers['Authorization'] = auth
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    print('Uploading to: $_photoUrl'); // TEMP
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    print('Upload response: ${res.statusCode} — ${res.body}'); // TEMP

    final payload = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode != 200 || payload?['success'] != true) {
      throw ProfileServiceException(
        payload?['error'] as String? ?? 'Upload failed',
      );
    }
    final avatar = payload!['avatar'] as Map<String, dynamic>?;
    return avatar?['avatarUrl'] as String? ?? '';
  }
}
