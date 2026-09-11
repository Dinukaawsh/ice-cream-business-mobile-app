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
    defaultValue:
        "835410660852-hg7q2o9nj0rlsnqohi4aau9bspm55hio.apps.googleusercontent.com",
  );

  /// iOS OAuth client ID from Google Cloud (optional, Android does not need this).
  static const String googleIosClientId = String.fromEnvironment(
    "GOOGLE_IOS_CLIENT_ID",
    defaultValue:
        "835410660852-h44cv4plpc2im3ofo1to782eobcjp2mt.apps.googleusercontent.com",
  );

  /// Meta / Facebook App ID. Do not commit real values.
  /// flutter run --dart-define-from-file=oauth.defines.json
  static const String facebookAppId = String.fromEnvironment("FACEBOOK_APP_ID");

  /// Facebook Client Token from Meta developer console. Do not commit real values.
  static const String facebookClientToken = String.fromEnvironment(
    "FACEBOOK_CLIENT_TOKEN",
  );

  static bool get isGoogleConfigured => googleServerClientId.trim().isNotEmpty;

  static bool get isFacebookConfigured =>
      facebookAppId.trim().isNotEmpty && facebookClientToken.trim().isNotEmpty;
}
