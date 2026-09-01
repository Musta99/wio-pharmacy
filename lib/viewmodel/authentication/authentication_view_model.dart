import 'package:flutter/material.dart';
import 'package:wio_pharmacy/core/services/auth_service.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';

enum AuthStatus { idle, loading, success, error }

class AuthenticationViewModel extends ChangeNotifier {
  AuthenticationViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus _status = AuthStatus.idle;
  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PharmacyAuthResult? _currentUser;
  PharmacyAuthResult? get currentUser => _currentUser;

  String? _cachedRole;
  String? get role => _cachedRole;

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final result = await _authService.loginPharmacy(
        email: email.trim(),
        password: password,
      );
      _currentUser = result;
      _cachedRole = result.role;
      _status = AuthStatus.success;
      _safeNotify();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      _safeNotify();
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = AuthStatus.error;
      _safeNotify();
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final loggedIn = await TokenService.instance.isLoggedIn();
    _cachedRole = loggedIn ? await TokenService.instance.getRole() : null;
    return loggedIn;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _cachedRole = null;
    _status = AuthStatus.idle;
    _safeNotify();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
