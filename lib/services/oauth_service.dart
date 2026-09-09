import "package:flutter/foundation.dart";
import "package:flutter_facebook_auth/flutter_facebook_auth.dart";
import "package:google_sign_in/google_sign_in.dart";

import "../config/app_config.dart";

class OAuthTokens {
  const OAuthTokens({required this.provider, required this.idToken});

  final String provider;
  final String idToken;
}

class OAuthService {
  OAuthService._();

  static final OAuthService instance = OAuthService._();

  GoogleSignIn? _google;
  var _facebookReady = false;

  Future<void> _ensureGoogle() async {
    if (_google != null) return;
    if (!AppConfig.isGoogleConfigured) {
      throw Exception(
        "Google sign-in is not configured. Set GOOGLE_SERVER_CLIENT_ID.",
      );
    }
    _google = GoogleSignIn(
      scopes: const ["email", "profile"],
      serverClientId: AppConfig.googleServerClientId.trim(),
      clientId: kIsWeb ? AppConfig.googleServerClientId.trim() : null,
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
        "Google did not return an ID token. Check GOOGLE_SERVER_CLIENT_ID matches the Web client ID.",
      );
    }
    return OAuthTokens(provider: "google", idToken: idToken);
  }

  Future<OAuthTokens> signInWithFacebook() async {
    await _ensureFacebook();
    final result = await FacebookAuth.instance.login(
      permissions: const ["email", "public_profile"],
    );
    if (result.status == LoginStatus.cancelled) {
      throw Exception("Facebook sign-in cancelled");
    }
    if (result.status != LoginStatus.success) {
      throw Exception(result.message ?? "Facebook sign-in failed");
    }
    final token = result.accessToken?.tokenString;
    if (token == null || token.length < 20) {
      throw Exception("Facebook did not return an access token");
    }
    return OAuthTokens(provider: "facebook", idToken: token);
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
