import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'primary_button.dart';

/// Confirmation modal used for release / suspend / delete actions.
/// Resolves to true when the user confirms.
Future<bool> showConfirmDialog({
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await Get.dialog<bool>(
    Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(message,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: confirmLabel,
              style: danger ? AppButtonStyle.danger : AppButtonStyle.primary,
              onPressed: () => Get.back(result: true),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Annuler',
              style: AppButtonStyle.surface,
              onPressed: () => Get.back(result: false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
