import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  static const _icones = [
    Icons.bookmark_added_outlined, // Réservations
    Icons.apartment_outlined, // Salles
    Icons.videocam_outlined, // Matériel
    Icons.person_outline, // Profil
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icones.length, (i) {
            final actif = i == index;
            return GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: actif ? AppColors.lime : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icones[i], size: 24, color: AppColors.encre),
              ),
            );
          }),
        ),
      ),
    );
  }
}
