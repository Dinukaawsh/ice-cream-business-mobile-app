import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../services/oauth_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../screens/home_screen.dart";
import "../screens/oauth_complete_registration_screen.dart";

class AuthSocialSection extends StatefulWidget {
  const AuthSocialSection({super.key, required this.api, this.enabled = true});

  final ApiService api;
  final bool enabled;

  @override
  State<AuthSocialSection> createState() => _AuthSocialSectionState();
}

class _AuthSocialSectionState extends State<AuthSocialSection> {
  String? _busy;

  Future<void> _run(String provider) async {
    if (!widget.enabled || _busy != null) return;
    setState(() => _busy = provider);
    try {
      final tokens = provider == "google"
          ? await OAuthService.instance.signInWithGoogle()
          : await OAuthService.instance.signInWithFacebook(context: context);

      try {
        final user = await widget.api.oauthLogin(
          provider: tokens.provider,
          idToken: tokens.idToken,
          nonce: tokens.nonce,
        );
        if (!mounted) return;
        showSuccessToast(context, "Signed in");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(api: widget.api, user: user),
          ),
          (_) => false,
        );
      } on OAuthBusinessNameRequired catch (required) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OAuthCompleteRegistrationScreen(
              api: widget.api,
              provider: tokens.provider,
              idToken: tokens.idToken,
              nonce: tokens.nonce,
              email: required.email,
              name: required.name,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst("Exception: ", "");
      debugPrint("OAUTH[$provider] error: $message");
      if (provider == "facebook" ||
          !message.toLowerCase().contains("cancelled")) {
        showErrorToast(context, message);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AuthOrDivider(),
        const SizedBox(height: 14),
        AuthSocialButton(
          label: "Continue with Google",
          provider: AuthSocialProvider.google,
          loading: _busy == "google",
          onPressed: widget.enabled && _busy == null
              ? () => _run("google")
              : null,
        ),
        const SizedBox(height: 10),
        AuthSocialButton(
          label: "Continue with Facebook",
          provider: AuthSocialProvider.facebook,
          loading: _busy == "facebook",
          onPressed: widget.enabled && _busy == null
              ? () => _run("facebook")
              : null,
        ),
      ],
    );
  }
}
