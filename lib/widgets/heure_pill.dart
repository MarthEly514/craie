import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class HeurePill extends StatelessWidget {
  final String heure;
  final VoidCallback? onTap;

  const HeurePill({super.key, required this.heure, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          heure,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.encre,
          ),
        ),
      ),
    );
  }
}