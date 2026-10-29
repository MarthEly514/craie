import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Small coloured label (Libre / Prise / Actif / Suspendu / Bon / En panne).
class StatusBadge extends StatelessWidget {
  final String label;
  final bool positive;

  const StatusBadge({super.key, required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: positive ? AppColors.chipGreen : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
