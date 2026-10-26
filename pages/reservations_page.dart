import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'barre_navigation.dart';
import 'couleurs.dart';

enum TypeReservation { salle, materiel }

class Reservation {
  const Reservation({
    required this.titre,
    required this.detail,
    required this.type,
  });

  final String titre;
  final String detail; 
  final TypeReservation type;
}

class ReservationsController extends GetxController {
  final reservations = <Reservation>[
    const Reservation(
      titre: 'Salle A2-2',
      detail: 'Zone master (Zogbadjè)',
      type: TypeReservation.salle,
    ),
    const Reservation(
      titre: 'Projecteur EpsonC10',
      detail: 'Epson C10-V12',
      type: TypeReservation.materiel,
    ),
    const Reservation(
      titre: 'Rallonge_5',
      detail: 'Rallonge 15m grise',
      type: TypeReservation.materiel,
    ),
  ].obs;

  final recherche = ''.obs;
  final filtre = Rxn<TypeReservation>(); 

  List<Reservation> get visibles {
    final q = recherche.value.trim().toLowerCase();
    return reservations.where((r) {
      final okType = filtre.value == null || r.type == filtre.value;
      final okTexte = q.isEmpty ||
          r.titre.toLowerCase().contains(q) ||
          r.detail.toLowerCase().contains(q);
      return okType && okTexte;
    }).toList();
  }

  void liberer(Reservation r) {
    reservations.remove(r);
    Get.snackbar(
      'Réservation libérée',
      r.titre,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ReservationsController());

    return Scaffold(
      backgroundColor: Couleurs.fond,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Réservations',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ChampRecherche(onChanged: (v) => c.recherche.value = v),
                  const SizedBox(height: 18),
                  Obx(() => Row(
                        children: [
                          _Filtre(
                            label: 'Toutes',
                            actif: c.filtre.value == null,
                            onTap: () => c.filtre.value = null,
                          ),
                          const SizedBox(width: 10),
                          _Filtre(
                            label: 'Matériel',
                            actif: c.filtre.value == TypeReservation.materiel,
                            onTap: () =>
                                c.filtre.value = TypeReservation.materiel,
                          ),
                          const SizedBox(width: 10),
                          _Filtre(
                            label: 'Salles',
                            actif: c.filtre.value == TypeReservation.salle,
                            onTap: () => c.filtre.value = TypeReservation.salle,
                          ),
                        ],
                      )),
                  const SizedBox(height: 16),
                  Obx(() {
                    final n = c.visibles.length;
                    return Text(
                      '${n.toString().padLeft(2, '0')} réservation${n > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Obx(() {
                      final liste = c.visibles;
                      if (liste.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucune réservation',
                            style: TextStyle(color: Couleurs.discret),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: liste.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _CarteReservation(
                          reservation: liste[i],
                          onDetails: () => _afficherDetails(liste[i]),
                          onLiberer: () => c.liberer(liste[i]),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  BarreNavigation(
                    indexActif: 0,
                    onTap: (i) {
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _afficherDetails(Reservation r) {
    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Couleurs.fond,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.titre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Couleurs.encre,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              r.detail,
              style: const TextStyle(fontSize: 15, color: Couleurs.discret),
            ),
            const SizedBox(height: 8),
            Text(
              r.type == TypeReservation.salle ? 'Salle' : 'Matériel',
              style: const TextStyle(fontSize: 13, color: Couleurs.discret),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampRecherche extends StatelessWidget {
  const _ChampRecherche({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Rechercher',
        hintStyle: const TextStyle(
          color: Couleurs.discret,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: const Icon(Icons.search, color: Couleurs.discret),
        filled: true,
        fillColor: Couleurs.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Filtre extends StatelessWidget {
  const _Filtre({
    required this.label,
    required this.actif,
    required this.onTap,
  });

  final String label;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: actif ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: actif ? Colors.black : Couleurs.discret,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: actif ? Colors.white : Couleurs.discret,
          ),
        ),
      ),
    );
  }
}

class _CarteReservation extends StatelessWidget {
  const _CarteReservation({
    required this.reservation,
    required this.onDetails,
    required this.onLiberer,
  });

  final Reservation reservation;
  final VoidCallback onDetails;
  final VoidCallback onLiberer;

  @override
  Widget build(BuildContext context) {
    final estSalle = reservation.type == TypeReservation.salle;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Couleurs.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.titre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (estSalle) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 20, color: Couleurs.discret),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        reservation.detail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Couleurs.discret,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Couleurs.discret, width: 1.5),
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(38),
                  ),
                  child: const Text(
                    'Détails',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onLiberer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Couleurs.lime,
                    foregroundColor: Couleurs.encre,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(38),
                  ),
                  child: const Text(
                    'Libérer',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}