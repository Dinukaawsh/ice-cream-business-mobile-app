import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../services/oauth_service.dart";
import "../widgets/app_chrome.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/confirm_dialog.dart";
import "business_settings_screen.dart";
import "customers_screen.dart";
import "login_screen.dart";
import "printer_settings_screen.dart";
import "reports_screen.dart";
import "returns_screen.dart";

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.api, required this.user});

  final ApiService api;
  final SessionUser user;

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showConfirmDialog(
      context,
      title: "Log out?",
      message: "You will need to sign in again to manage your business.",
      confirmLabel: "Log out",
      isDanger: true,
    );
    if (!shouldLogout || !context.mounted) return;
    await OAuthService.instance.signOutProviders();
    await api.clearToken();
    if (!context.mounted) return;
    showSuccessToast(context, "Logged out");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(api: api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: "More",
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AuthColors.ink,
            ),
          ),
          Text(
            user.email,
            style: const TextStyle(color: AuthColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          _MoreTile(
            icon: Icons.people_outline,
            title: "Customers",
            subtitle: "Shops and walk-in people",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CustomersScreen(api: api)),
            ),
          ),
          _MoreTile(
            icon: Icons.assignment_return_outlined,
            title: "Returns",
            subtitle: "Shop returns and credit",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReturnsScreen(api: api)),
            ),
          ),
          _MoreTile(
            icon: Icons.bar_chart_rounded,
            title: "Reports",
            subtitle: "Sales, PDF, daily totals",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReportsScreen(api: api)),
            ),
          ),
          _MoreTile(
            icon: Icons.storefront_outlined,
            title: "Business settings",
            subtitle: "Shop name, logo, bill details",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BusinessSettingsScreen(api: api),
              ),
            ),
          ),
          _MoreTile(
            icon: Icons.print_outlined,
            title: "Bluetooth printer",
            subtitle: "Pair a receipt printer",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrinterSettingsScreen(),
              ),
            ),
          ),
          _MoreTile(
            icon: Icons.receipt_long_outlined,
            title: "Bill preview",
            subtitle: "See how a printed bill looks",
            onTap: () async {
              try {
                final settings = await api.fetchBusinessSettings();
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BillPreviewScreen(settings: settings),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                showErrorToast(
                  context,
                  error.toString().replaceFirst("Exception: ", ""),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _MoreTile(
            icon: Icons.logout_rounded,
            title: "Log out",
            subtitle: "Sign out of this device",
            danger: true,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppSurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            AppIconBadge(icon: icon, muted: danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: danger ? const Color(0xFFB91C1C) : AuthColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AuthColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: danger ? const Color(0xFFB91C1C) : AuthColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
