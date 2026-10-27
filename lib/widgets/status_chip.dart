import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class StatusChip extends StatelessWidget {
  final bool libre;

  const StatusChip({super.key, required this.libre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: libre ? AppColors.lime : AppColors.corailClair,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        libre ? 'Libre' : 'Prise',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: libre ? AppColors.encre : AppColors.corail,
        ),
      ),
    );
  }
}