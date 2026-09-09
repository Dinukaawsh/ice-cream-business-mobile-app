class AppConfig {
  /// Hosted API (Vercel). Override locally with:
  /// --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://ice-cream-business.vercel.app",
  );

  /// Google Cloud **Web** OAuth client ID (must match server GOOGLE_CLIENT_ID).
  /// flutter run --dart-define-from-file=oauth.defines.json
  static const String googleServerClientId = String.fromEnvironment(
    "GOOGLE_SERVER_CLIENT_ID",
  );

  /// iOS OAuth client ID from Google Cloud (optional, Android does not need this).
  static const String googleIosClientId = String.fromEnvironment(
    "GOOGLE_IOS_CLIENT_ID",
  );

  /// Meta / Facebook App ID (also set in Android strings.xml + iOS Info.plist).
  /// --dart-define=FACEBOOK_APP_ID=1234567890
  static const String facebookAppId = String.fromEnvironment(
    "FACEBOOK_APP_ID",
    defaultValue: "REDACTED",
  );

  /// Facebook Client Token from Meta developer console.
  /// --dart-define=FACEBOOK_CLIENT_TOKEN=...
  static const String facebookClientToken = String.fromEnvironment(
    "FACEBOOK_CLIENT_TOKEN",
    defaultValue: "REDACTED",
  );

  static bool get isGoogleConfigured => googleServerClientId.trim().isNotEmpty;

  static bool get isFacebookConfigured =>
      facebookAppId.trim().isNotEmpty && facebookClientToken.trim().isNotEmpty;
}
