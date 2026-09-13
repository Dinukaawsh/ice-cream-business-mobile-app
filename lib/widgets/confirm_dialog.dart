import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "auth_ui.dart";

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = "Confirm",
  String cancelLabel = "Cancel",
  bool isDanger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: GoogleFonts.fraunces(
          fontWeight: FontWeight.w700,
          color: AuthColors.blueberry,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AuthColors.muted, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AuthColors.primaryDeep,
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: isDanger
                      ? const Color(0xFFDC2626)
                      : AuthColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return result ?? false;
}
