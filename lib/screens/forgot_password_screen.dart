import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  var _step = 0;
  var _loading = false;
  var _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _loading = true);
    try {
      final message = await widget.api.forgotPassword(
        email: _email.text.trim(),
      );
      if (!mounted) return;
      setState(() => _step = 1);
      showSuccessToast(context, message);
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

  Future<void> _resetPassword() async {
    if (_password.text != _confirm.text) {
      showErrorToast(context, "Passwords do not match");
      return;
    }
    setState(() => _loading = true);
    try {
      final message = await widget.api.resetPassword(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      showSuccessToast(context, message);
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
              AuthHero(
                compact: true,
                title: _step == 0 ? "Reset password" : "Enter your code",
                subtitle: _step == 0
                    ? "We’ll email a 6-digit code to unlock a new password."
                    : "Use the code from your inbox, then choose a strong password.",
              ),
              const SizedBox(height: 28),
              AuthField(
                controller: _email,
                label: "Email",
                hint: "you@shop.com",
                enabled: _step == 0,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              if (_step == 1) ...[
                const SizedBox(height: 14),
                AuthField(
                  controller: _otp,
                  label: "6-digit OTP",
                  hint: "123456",
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                ),
                const SizedBox(height: 14),
                AuthField(
                  controller: _password,
                  label: "New password",
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
                const SizedBox(height: 14),
                AuthField(
                  controller: _confirm,
                  label: "Confirm password",
                  hint: "Repeat password",
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
              ],
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: _step == 0 ? "Send OTP" : "Reset password",
                loading: _loading,
                onPressed: _loading
                    ? null
                    : () {
                        if (_step == 0) {
                          _sendCode();
                        } else {
                          _resetPassword();
                        }
                      },
              ),
              if (_step == 1) ...[
                const SizedBox(height: 12),
                AuthGhostButton(
                  label: "Resend code",
                  onPressed: _loading ? null : _sendCode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
