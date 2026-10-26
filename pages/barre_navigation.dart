import 'package:flutter/material.dart';

import 'couleurs.dart';

class BarreNavigation extends StatelessWidget {
  const BarreNavigation({
    super.key,
    required this.indexActif,
    required this.onTap,
  });

  final int indexActif;
  final ValueChanged<int> onTap;

  static const _icones = [
    Icons.bookmark_added_outlined,
    Icons.apartment_outlined,
    Icons.videocam_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Couleurs.surface,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_icones.length, (i) {
          final actif = i == indexActif;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: actif ? Couleurs.lime : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(_icones[i], size: 26, color: Couleurs.encre),
            ),
          );
        }),
      ),
    );
  }
}