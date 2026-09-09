import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/oauth_buttons.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _businessName = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  var _obscure = true;

  @override
  void dispose() {
    _businessName.dispose();
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await widget.api.register(
        businessName: _businessName.text.trim(),
        name: _name.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      showSuccessToast(
        context,
        "Check your email to verify your account, then sign in.",
      );
      Navigator.of(context).pop();
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
              const AuthHero(
                compact: true,
                title: "Open your shop",
                subtitle:
                    "Tell us about your business. These details print on bill headers.",
              ),
              const SizedBox(height: 20),
              AuthSocialSection(api: widget.api, enabled: !_loading),
              const SizedBox(height: 20),
              const AuthSectionLabel("Business"),
              const SizedBox(height: 12),
              AuthField(
                controller: _businessName,
                label: "Business name",
                hint: "Sweet Scoop Co.",
                prefixIcon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _name,
                label: "Owner name",
                hint: "Your name",
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _address,
                label: "Address",
                hint: "Street, city (optional)",
                maxLines: 2,
                prefixIcon: Icons.place_outlined,
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _phone,
                label: "Phone",
                hint: "Optional",
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 28),
              const AuthSectionLabel("Account"),
              const SizedBox(height: 12),
              AuthField(
                controller: _email,
                label: "Email",
                hint: "you@shop.com",
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _password,
                label: "Password",
                hint: "Min 10 chars, upper, lower, number",
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AuthColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: "Create account",
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(
                    "Already have an account? Sign in",
                    style: authBodyStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AuthColors.primaryDeep,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
