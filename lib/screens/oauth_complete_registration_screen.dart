import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "home_screen.dart";

class OAuthCompleteRegistrationScreen extends StatefulWidget {
  const OAuthCompleteRegistrationScreen({
    super.key,
    required this.api,
    required this.provider,
    required this.idToken,
    required this.email,
    required this.name,
  });

  final ApiService api;
  final String provider;
  final String idToken;
  final String email;
  final String name;

  @override
  State<OAuthCompleteRegistrationScreen> createState() =>
      _OAuthCompleteRegistrationScreenState();
}

class _OAuthCompleteRegistrationScreenState
    extends State<OAuthCompleteRegistrationScreen> {
  late final TextEditingController _businessName;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _businessName = TextEditingController();
  }

  @override
  void dispose() {
    _businessName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _businessName.text.trim();
    if (name.length < 2) {
      showErrorToast(context, "Enter your shop / business name");
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await widget.api.oauthLogin(
        provider: widget.provider,
        idToken: widget.idToken,
        businessName: name,
      );
      if (!mounted) return;
      showSuccessToast(context, "Welcome to Scooply");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(api: widget.api, user: user),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: authFormMaxWidth(context)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            children: [
              AuthHero(
                compact: true,
                title: "Name your shop",
                subtitle:
                    "Signed in as ${widget.email}. One more step to finish.",
              ),
              const SizedBox(height: 28),
              AuthField(
                controller: _businessName,
                label: "Business name",
                hint: "Sweet Scoop Co.",
                prefixIcon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 12),
              Text(
                "Owner: ${widget.name}",
                style: authBodyStyle(size: 13, color: AuthColors.muted),
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: "Finish & open shop",
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
