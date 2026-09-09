import "dart:convert";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_facebook_auth/flutter_facebook_auth.dart";
import "package:google_sign_in/google_sign_in.dart";

import "../config/app_config.dart";
import "../screens/facebook_web_login_screen.dart";

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

  static const _releaseKeyHash = "78SiNQuLCRNGfPCwfmlxVfxUjKg=";
  static const _debugKeyHash = "zq+VIarr0khKGR4cRCmi1WloaP0=";

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
          : (defaultTargetPlatform == TargetPlatform.iOS &&
                  iosClientId.isNotEmpty
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

  Future<void> _clearGoogleSession() async {
    await _ensureGoogle();
    try {
      await _google!.disconnect();
    } catch (_) {
      try {
        await _google!.signOut();
      } catch (_) {}
    }
  }

  Future<OAuthTokens> signInWithGoogle() async {
    await _clearGoogleSession();
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

  Future<LoginResult> _facebookLogin({
    required LoginBehavior behavior,
    required LoginTracking tracking,
    required String nonce,
  }) {
    return FacebookAuth.instance.login(
      permissions: const ["email", "public_profile"],
      loginBehavior: behavior,
      loginTracking: tracking,
      nonce: nonce,
    );
  }

  String _facebookFailMessage(LoginResult result) {
    final raw = result.message?.trim() ?? "";
    if (raw.isNotEmpty) return raw;
    return "Facebook sign-in failed. In Meta → Facebook Login → Settings, add package com.icecream.app.icecream_mobile and both key hashes: $_debugKeyHash (debug) and $_releaseKeyHash (release).";
  }

  Future<OAuthTokens> signInWithFacebook({BuildContext? context}) async {
    await _ensureFacebook();
    debugPrint(
      "FB login start appId=${AppConfig.facebookAppId} "
      "tokenSet=${AppConfig.facebookClientToken.isNotEmpty}",
    );
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        context != null &&
        context.mounted) {
      debugPrint("FB attempt in-app webview");
      final token = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const FacebookWebLoginScreen()),
      );
      if (token == null || token.length < 20) {
        throw Exception("Facebook sign-in cancelled");
      }
      debugPrint("FB token type=classic len=${token.length} jwt=false");
      return OAuthTokens(provider: "facebook", idToken: token);
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (error) {
      debugPrint("FB logout ignored: $error");
    }

    final nonce = _createNonce();
    var result = await _facebookLogin(
      behavior: LoginBehavior.webOnly,
      tracking: LoginTracking.enabled,
      nonce: nonce,
    );
    debugPrint(
      "FB attempt web/enabled status=${result.status} "
      "message=${result.message} type=${result.accessToken?.type}",
    );

    if (result.status != LoginStatus.success &&
        result.status != LoginStatus.cancelled) {
      result = await _facebookLogin(
        behavior: LoginBehavior.webOnly,
        tracking: LoginTracking.limited,
        nonce: nonce,
      );
      debugPrint(
        "FB attempt web/limited status=${result.status} message=${result.message}",
      );
    }

    if (result.status == LoginStatus.cancelled) {
      throw Exception(
        result.message?.trim().isNotEmpty == true
            ? "Facebook cancelled: ${result.message}"
            : "Facebook sign-in cancelled",
      );
    }
    if (result.status != LoginStatus.success) {
      throw Exception(_facebookFailMessage(result));
    }
    final access = result.accessToken;
    if (access == null) {
      throw Exception("Facebook did not return an access token");
    }
    final token = access.tokenString;
    debugPrint(
      "FB token type=${access.type} len=${token.length} jwt=${token.split(".").length == 3}",
    );
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
      await _ensureGoogle();
      await _google!.disconnect();
    } catch (_) {
      try {
        await _google?.signOut();
      } catch (_) {}
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
