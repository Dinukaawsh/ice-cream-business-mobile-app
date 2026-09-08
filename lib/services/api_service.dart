import "dart:convert";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../config/app_config.dart";
import "../models/business_settings.dart";
import "../models/dashboard_summary.dart";

class SessionUser {
  SessionUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.businessId,
  });

  final int id;
  final String email;
  final String name;
  final String role;
  final String status;
  final int? businessId;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json["id"] as int,
      email: json["email"] as String,
      name: json["name"] as String,
      role: json["role"] as String,
      status: json["status"] as String,
      businessId: json["businessId"] as int?,
    );
  }
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final String _baseUrl = AppConfig.apiBaseUrl;
  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("auth_token");
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }

  Map<String, String> _headers({bool auth = false}) {
    return {
      "Content-Type": "application/json",
      if (auth && _token != null) "Authorization": "Bearer $_token",
    };
  }

  Future<SessionUser?> fetchMe() async {
    if (_token == null) return null;
    final response = await _client.get(
      Uri.parse("$_baseUrl/api/auth/me"),
      headers: _headers(auth: true),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final user = SessionUser.fromJson(data["user"] as Map<String, dynamic>);
    if (user.role == "platform_admin") {
      await clearToken();
      throw Exception("Use the web admin for platform admin accounts");
    }
    return user;
  }

  Future<SessionUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/api/auth/login"),
      headers: _headers(),
      body: jsonEncode({"email": email, "password": password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Login failed");
    }
    final user = SessionUser.fromJson(data["user"] as Map<String, dynamic>);
    if (user.role == "platform_admin") {
      throw Exception("Use the web admin for platform admin accounts");
    }
    await _saveToken(data["token"] as String);
    return user;
  }

  Future<void> register({
    required String businessName,
    required String name,
    required String email,
    required String password,
    String address = '',
    String phone = '',
  }) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/api/auth/register"),
      headers: _headers(),
      body: jsonEncode({
        "businessName": businessName,
        "name": name,
        "email": email,
        "password": password,
        "address": address,
        "phone": phone,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data["error"] ?? "Registration failed");
    }
  }

  Future<BusinessSettings> fetchBusinessSettings() async {
    final response = await _client.get(
      Uri.parse("$_baseUrl/api/settings/business"),
      headers: _headers(auth: true),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Could not load business settings");
    }
    return BusinessSettings.fromJson(
      data["settings"] as Map<String, dynamic>,
    );
  }

  Future<DashboardSummary> fetchDashboardSummary() async {
    final response = await _client.get(
      Uri.parse("$_baseUrl/api/dashboard/summary"),
      headers: _headers(auth: true),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Could not load dashboard");
    }
    return DashboardSummary.fromJson(
      data["dashboard"] as Map<String, dynamic>,
    );
  }

  Future<BusinessSettings> updateBusinessSettings({
    required String businessName,
    required String ownerName,
    required String address,
    required String phone,
    required String email,
  }) async {
    final response = await _client.patch(
      Uri.parse("$_baseUrl/api/settings/business"),
      headers: _headers(auth: true),
      body: jsonEncode({
        "businessName": businessName,
        "ownerName": ownerName,
        "address": address,
        "phone": phone,
        "email": email,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Could not save business settings");
    }
    return BusinessSettings.fromJson(
      data["settings"] as Map<String, dynamic>,
    );
  }

  Future<BusinessSettings> uploadBusinessLogo({
    required String dataUri,
  }) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/api/settings/business/logo"),
      headers: _headers(auth: true),
      body: jsonEncode({"dataUri": dataUri}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Logo upload failed");
    }
    return BusinessSettings.fromJson(
      data["settings"] as Map<String, dynamic>,
    );
  }

  Future<BusinessSettings> removeBusinessLogo() async {
    final response = await _client.delete(
      Uri.parse("$_baseUrl/api/settings/business/logo"),
      headers: _headers(auth: true),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Could not remove logo");
    }
    return BusinessSettings.fromJson(
      data["settings"] as Map<String, dynamic>,
    );
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/api/auth/forgot-password"),
      headers: _headers(),
      body: jsonEncode({"email": email}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Could not send reset code");
    }
    return data["message"] as String? ??
        "If an account exists for that email, a reset code has been sent.";
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/api/auth/reset-password"),
      headers: _headers(),
      body: jsonEncode({
        "email": email,
        "otp": otp,
        "password": password,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Could not reset password");
    }
    return data["message"] as String? ?? "Password updated.";
  }

  Future<SessionUser> oauthLogin({
    required String provider,
    required String idToken,
    String? businessName,
  }) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/api/auth/oauth"),
      headers: _headers(),
      body: jsonEncode({
        "provider": provider,
        "idToken": idToken,
        "businessName": ?businessName,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 409 && data["error"] == "businessName_required") {
      throw OAuthBusinessNameRequired(
        email: data["email"] as String? ?? "",
        name: data["name"] as String? ?? "",
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data["error"] ?? "OAuth login failed");
    }
    await _saveToken(data["token"] as String);
    return SessionUser.fromJson(data["user"] as Map<String, dynamic>);
  }
}

class OAuthBusinessNameRequired implements Exception {
  OAuthBusinessNameRequired({required this.email, required this.name});
  final String email;
  final String name;
}
