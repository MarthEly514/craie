import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppButtonStyle { primary, surface, dark, danger, outlineDanger }

/// Full-width pill button used across the app.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.loading = false
  });

  @override
  Widget build(BuildContext context) {
    const text = TextStyle(fontWeight: FontWeight.w600, fontSize: 14);
    if (style == AppButtonStyle.outlineDanger) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            shape: const StadiumBorder(),
            textStyle: text,
          ),
          child: loading ? 
          const SizedBox(height: 20, width: 20, 
            child: CircularProgressIndicator(strokeWidth: 2)) 
          : Text(label),
        ),
      );
    }
    final (bg, fg) = switch (style) {
      AppButtonStyle.primary => (AppColors.primary, Colors.black),
      AppButtonStyle.surface => (AppColors.surface, Colors.black),
      AppButtonStyle.dark => (AppColors.dark, Colors.white),
      _ => (AppColors.danger, Colors.black),
    };
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: const StadiumBorder(),
          textStyle: text,
        ),
        child: loading ? 
          const SizedBox(height: 20, width: 20, 
            child: CircularProgressIndicator(strokeWidth: 2)) 
          : Text(label),
      ),
    );
  }
}
