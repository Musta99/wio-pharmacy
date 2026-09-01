class ApiConstants {
  ApiConstants._();

  // TODO: replace with your actual values (or import from your existing constants file)
  static const String firebaseWebApiKey =
      'AIzaSyAe4Y00uoLRmwxfeL2FdxPyroLekn1jLn8';
  static const String backendBaseUrl = 'https://www.wiocare.com';

  static const String identityToolkitSignInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseWebApiKey';
  static const String secureTokenRefreshUrl =
      'https://securetoken.googleapis.com/v1/token?key=$firebaseWebApiKey';
  static const String backendSigninUrl = '$backendBaseUrl/api/auth/signin';

  // in api_constants.dart
  static const String googleMapsApiKey =
      'AIzaSyBK5-pwhZyjEIPVHx5fr0TTSrlHYJe5FZ8'; // optional — leave empty to skip reverse geocoding
}
