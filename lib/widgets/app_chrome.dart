import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "auth_ui.dart";

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: AuthColors.frost,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x142F6FED),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFE0EAFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F1D4ED8),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.muted = false,
  });

  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: muted
            ? null
            : const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: muted ? const Color(0xFFF1F5F9) : null,
      ),
      child: Icon(
        icon,
        color: muted ? AuthColors.muted : AuthColors.primaryDeep,
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.tone = AppChipTone.neutral,
  });

  final String label;
  final AppChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppChipTone.danger => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      AppChipTone.warning => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      AppChipTone.success => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      AppChipTone.neutral => (const Color(0xFFEFF6FF), AuthColors.primaryDeep),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum AppChipTone { neutral, success, warning, danger }

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 88, 28, 28),
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: AuthColors.primary),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AuthColors.muted, height: 1.4),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 22),
          Center(
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
