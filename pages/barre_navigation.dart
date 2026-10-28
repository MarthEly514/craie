import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'couleurs.dart';
import 'materiel_page.dart';
import 'profil_page.dart';
import 'reservations_page.dart';
import 'salles_page.dart';

/// Barre de navigation du bas, commune à toutes les pages.
/// 0 = Réservations, 1 = Salles, 2 = Matériel, 3 = Profil
class BarreNavigation extends StatelessWidget {
  const BarreNavigation({super.key, required this.indexActif});

  final int indexActif;

  static const _icones = [
    Icons.bookmark_added_outlined,
    Icons.apartment_outlined,
    Icons.videocam_outlined,
    Icons.person_outline,
  ];

  // Les pages, dans le même ordre que les icônes
  static final List<Widget Function()> _pages = [
    () => const ReservationsPage(),
    () => const SallesPage(),
    () => const MaterielPage(),
    () => const ProfilPage(),
  ];

  void _aller(int i) {
    // Si on clique sur la page où on est déjà, on ne fait rien
    if (i == indexActif) return;

    // Get.offAll : ouvre la page et remplace l'ancienne (pas de retour en arrière)
    Get.offAll(_pages[i], transition: Transition.noTransition);
  }

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
            onTap: () => _aller(i),
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