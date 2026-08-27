/// Google OAuth 2.0 Configuration
/// 
/// To enable real Google Sign-In:
/// 1. Go to Google Cloud Console (https://console.cloud.google.com/apis/credentials)
/// 2. Create an "OAuth 2.0 Client ID" with application type "Web application".
/// 3. In Authorized JavaScript origins, add:
///    - http://localhost
///    - http://localhost:7357 (or the port flutter run uses)
/// 4. Paste your Web Client ID into [googleWebClientId] below.
class AuthConfig {
  /// Google OAuth Web Client ID
  /// (Configured with your Google Cloud Console Web Client ID)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '755414718888-jbm6o2po5vl0s8poq79gou8i1g0l4gpo.apps.googleusercontent.com',
  );

  /// Optional: Server client ID for backend verification if required
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Helper to check if a real client ID is configured
  static bool get isCustomGoogleClientIdConfigured =>
      googleWebClientId.isNotEmpty && !googleWebClientId.contains('default');
}
