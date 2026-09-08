class AppConfig {
  /// Hosted API (Vercel). Override locally with:
  /// --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://ice-cream-business.vercel.app",
  );
}
