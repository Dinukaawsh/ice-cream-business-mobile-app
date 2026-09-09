import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/brand.dart';
import '../widgets/brand_logo.dart';

/// Soft frost palette — sky ice, mint glaze, blueberry ink.
class AuthColors {
  static const skyTop = Color(0xFFB9E0FF);
  static const skyMid = Color(0xFFE8F4FF);
  static const frost = Color(0xFFF7FBFF);
  static const mint = Color(0xFF9FE7D0);
  static const scoop = Color(0xFFFFB4C8);
  static const blueberry = Color(0xFF1B3A6B);
  static const ink = Color(0xFF16324F);
  static const muted = Color(0xFF5B7390);
  static const fieldFill = Color(0xFFFFFFF8);
  static const primary = Color(0xFF2F6FED);
  static const primaryDeep = Color(0xFF1D4ED8);
}

TextStyle authBrandStyle({double size = 42, Color? color}) {
  return GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.8,
    color: color ?? AuthColors.blueberry,
  );
}

TextStyle authBodyStyle({
  double size = 15,
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return GoogleFonts.outfit(
    fontSize: size,
    fontWeight: weight,
    height: 1.4,
    color: color ?? AuthColors.muted,
  );
}

class AuthShell extends StatefulWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showBack = false,
  });

  final Widget child;
  final bool showBack;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final t = _motion.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AuthColors.skyTop,
                      AuthColors.skyMid,
                      AuthColors.frost,
                      Color(0xFFEAFBF5),
                    ],
                    stops: [0, 0.35, 0.72, 1],
                  ),
                ),
              ),
              Positioned(
                top: -40 + (t * 18),
                right: -30,
                child: _Blob(
                  size: 220,
                  colors: [
                    AuthColors.scoop.withValues(alpha: 0.55),
                    AuthColors.scoop.withValues(alpha: 0.05),
                  ],
                ),
              ),
              Positioned(
                top: 120 + (t * -12),
                left: -60,
                child: _Blob(
                  size: 180,
                  colors: [
                    AuthColors.mint.withValues(alpha: 0.5),
                    AuthColors.mint.withValues(alpha: 0.02),
                  ],
                ),
              ),
              Positioned(
                bottom: 40 + (t * 20),
                right: -20,
                child: _Blob(
                  size: 160,
                  colors: [
                    AuthColors.primary.withValues(alpha: 0.22),
                    AuthColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
              Positioned(
                bottom: 180,
                left: 24 + (t * 10),
                child: Transform.rotate(
                  angle: -0.2 + (t * 0.08),
                  child: Opacity(
                    opacity: 0.18,
                    child: Image.asset(
                      Brand.logoAsset,
                      width: 92,
                      height: 92,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    if (widget.showBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AuthColors.blueberry,
                        ),
                      ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BrandLogo(size: compact ? 44 : 54),
              const SizedBox(width: 12),
              Text(
                Brand.name,
                style: authBrandStyle(size: compact ? 28 : 34),
              ),
            ],
          ),
          SizedBox(height: compact ? 18 : 28),
          Text(title, style: authBrandStyle(size: compact ? 26 : 32)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: authBodyStyle(size: 15, color: AuthColors.muted),
          ),
        ],
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.prefixIcon,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: authBodyStyle(
            size: 13,
            weight: FontWeight.w600,
            color: AuthColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLines: maxLines,
              enabled: enabled,
              style: authBodyStyle(
                size: 15,
                weight: FontWeight.w500,
                color: AuthColors.ink,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: authBodyStyle(size: 14, color: AuthColors.muted),
                filled: true,
                fillColor: AuthColors.fieldFill.withValues(alpha: 0.92),
                prefixIcon: prefixIcon == null
                    ? null
                    : Icon(prefixIcon, color: AuthColors.primary, size: 22),
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AuthColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AuthColors.primary,
                    width: 1.6,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AuthColors.muted.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: onPressed == null || loading
                ? [const Color(0xFF93C5FD), const Color(0xFF93C5FD)]
                : const [AuthColors.primary, AuthColors.primaryDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AuthColors.primary.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: authBodyStyle(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGhostButton extends StatelessWidget {
  const AuthGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AuthColors.blueberry,
          side: BorderSide(
            color: AuthColors.blueberry.withValues(alpha: 0.18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.45),
        ),
        child: Text(
          label,
          style: authBodyStyle(
            size: 15,
            weight: FontWeight.w600,
            color: AuthColors.blueberry,
          ),
        ),
      ),
    );
  }
}

class AuthSectionLabel extends StatelessWidget {
  const AuthSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: authBodyStyle(
        size: 11,
        weight: FontWeight.w700,
        color: AuthColors.primary,
      ).copyWith(letterSpacing: 1.4),
    );
  }
}

double authFormMaxWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return math.min(width, 480);
}
