import "package:flutter/material.dart";
import "package:webview_flutter/webview_flutter.dart";
import "package:webview_flutter_android/webview_flutter_android.dart";

import "../config/app_config.dart";
import "../widgets/auth_ui.dart";

/// Facebook mobile web shows an "Open app" banner and never returns a token.
/// A desktop-UA WebView keeps login on the page and blocks app-switch URLs.
class FacebookWebLoginScreen extends StatefulWidget {
  const FacebookWebLoginScreen({super.key});

  @override
  State<FacebookWebLoginScreen> createState() => _FacebookWebLoginScreenState();
}

class _FacebookWebLoginScreenState extends State<FacebookWebLoginScreen> {
  static const _desktopUa =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

  late final WebViewController _controller;
  var _done = false;
  var _loading = true;

  Uri get _oauthUri {
    return Uri.https("www.facebook.com", "/v21.0/dialog/oauth", {
      "client_id": AppConfig.facebookAppId.trim(),
      "redirect_uri": "https://www.facebook.com/connect/login_success.html",
      "response_type": "token",
      "scope": "email,public_profile",
      "display": "popup",
      "auth_type": "rerequest",
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_desktopUa)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isAppHandoff(request.url)) {
              return NavigationDecision.prevent;
            }
            _maybeComplete(request.url);
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _maybeComplete(url);
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _loading = false);
            _maybeComplete(url);
            try {
              final href = await _controller.runJavaScriptReturningResult(
                "window.location.href",
              );
              _maybeComplete(href.toString().replaceAll('"', ""));
            } catch (_) {}
          },
          onWebResourceError: (error) {
            final url = error.url;
            if (url != null) _maybeComplete(url);
          },
        ),
      );
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final cookies = WebViewCookieManager().platform;
      if (cookies is AndroidWebViewCookieManager) {
        cookies.setAcceptThirdPartyCookies(platform, true);
      }
    }
    _controller.loadRequest(_oauthUri);
  }

  bool _isAppHandoff(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith("intent:") ||
        lower.startsWith("fb://") ||
        lower.startsWith("fbapi") ||
        lower.startsWith("fb-messenger") ||
        lower.startsWith("market:") ||
        lower.contains("play.google.com/store") ||
        lower.contains("apps.apple.com") ||
        lower.contains("m.facebook.com/click.php") && lower.contains("app");
  }

  String? _accessToken(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return null;
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return null;
    }
    final params = <String, String>{
      ...uri.queryParameters,
      if (uri.fragment.isNotEmpty) ...Uri.splitQueryString(uri.fragment),
    };
    if ((params["error"] ?? "").isNotEmpty) {
      _finish(null);
      return null;
    }
    final token = params["access_token"]?.trim() ?? "";
    if (token.length < 20) return null;
    return token;
  }

  void _maybeComplete(String url) {
    if (_done) return;
    final hasTokenHint = url.contains("login_success.html") ||
        url.startsWith("fb${AppConfig.facebookAppId}") ||
        url.contains("access_token=");
    if (!hasTokenHint) return;
    final token = _accessToken(url);
    if (token != null) _finish(token);
  }

  void _finish(String? token) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AuthColors.blueberry,
        foregroundColor: Colors.white,
        title: const Text("Facebook"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
