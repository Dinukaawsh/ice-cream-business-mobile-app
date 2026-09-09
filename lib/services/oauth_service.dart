import "dart:convert";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter_facebook_auth/flutter_facebook_auth.dart";
import "package:google_sign_in/google_sign_in.dart";

import "../config/app_config.dart";

class OAuthTokens {
  const OAuthTokens({
    required this.provider,
    required this.idToken,
    this.nonce,
  });

  final String provider;
  final String idToken;
  final String? nonce;
}

class OAuthService {
  OAuthService._();

  static final OAuthService instance = OAuthService._();

  GoogleSignIn? _google;
  var _facebookReady = false;

  String _createNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll("=", "");
  }

  Future<void> _ensureGoogle() async {
    if (_google != null) return;
    if (!AppConfig.isGoogleConfigured) {
      throw Exception(
        "Google sign-in is not configured. Add your Web client ID to mobile/oauth.defines.json as GOOGLE_SERVER_CLIENT_ID, then run with --dart-define-from-file=oauth.defines.json.",
      );
    }
    final webClientId = AppConfig.googleServerClientId.trim();
    final iosClientId = AppConfig.googleIosClientId.trim();
    _google = GoogleSignIn(
      scopes: const ["email", "profile", "openid"],
      serverClientId: webClientId,
      clientId: kIsWeb
          ? webClientId
          : (defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty
              ? iosClientId
              : null),
    );
  }

  Future<void> _ensureFacebook() async {
    if (_facebookReady) return;
    if (!AppConfig.isFacebookConfigured) {
      throw Exception(
        "Facebook sign-in is not configured. Set FACEBOOK_APP_ID and FACEBOOK_CLIENT_TOKEN.",
      );
    }
    if (kIsWeb) {
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: AppConfig.facebookAppId.trim(),
        cookie: true,
        xfbml: true,
        version: "v21.0",
      );
    }
    _facebookReady = true;
  }

  Future<OAuthTokens> signInWithGoogle() async {
    await _ensureGoogle();
    final account = await _google!.signIn();
    if (account == null) {
      throw Exception("Google sign-in cancelled");
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.length < 20) {
      throw Exception(
        "Google did not return an ID token. Use the Web OAuth client ID as GOOGLE_SERVER_CLIENT_ID, and register this app's SHA-1 in Google Cloud.",
      );
    }
    return OAuthTokens(provider: "google", idToken: idToken);
  }

  Future<OAuthTokens> signInWithFacebook() async {
    await _ensureFacebook();
    final nonce = _createNonce();
    var result = await FacebookAuth.instance.login(
      permissions: const ["email", "public_profile"],
      loginBehavior: LoginBehavior.nativeWithFallback,
      loginTracking: LoginTracking.enabled,
      nonce: nonce,
    );
    if (result.status != LoginStatus.success &&
        result.status != LoginStatus.cancelled) {
      result = await FacebookAuth.instance.login(
        permissions: const ["email", "public_profile"],
        loginBehavior: LoginBehavior.nativeWithFallback,
        loginTracking: LoginTracking.limited,
        nonce: nonce,
      );
    }
    if (result.status == LoginStatus.cancelled) {
      throw Exception("Facebook sign-in cancelled");
    }
    if (result.status != LoginStatus.success) {
      throw Exception(
        result.message?.trim().isNotEmpty == true
            ? result.message!
            : "Facebook sign-in failed. Add the Android key hash from the README in Meta Developer settings.",
      );
    }
    final access = result.accessToken;
    if (access == null) {
      throw Exception("Facebook did not return an access token");
    }
    final token = access.tokenString;
    if (token.length < 20) {
      throw Exception("Facebook did not return an access token");
    }
    return OAuthTokens(
      provider: "facebook",
      idToken: token,
      nonce: nonce,
    );
  }

  Future<void> signOutProviders() async {
    try {
      await _google?.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
