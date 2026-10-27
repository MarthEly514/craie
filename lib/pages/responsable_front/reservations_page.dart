import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/reservations_controller.dart';
import '../../core/app_theme.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/search_field.dart';

import '../../data/models/reservation.dart';
import 'materiel_detail_page.dart';
import 'salle_detail_page.dart';

class ReservationsPage extends StatelessWidget {
  final VoidCallback? onReserver;

  const ReservationsPage({super.key, this.onReserver});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ReservationsController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Réservations',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SearchField(onChanged: (v) => c.recherche.value = v),
              const SizedBox(height: 12),
              Obx(
                () => FilterChips(
                  labels: const ['Toutes', 'Matériel', 'Salles'],
                  selected: c.filtre.value,
                  onSelected: (l) => c.filtre.value = l,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final liste = c.affichees;

                  if (liste.isEmpty) {
                    return _EtatVide(onReserver: onReserver);
                  }

                  final n = liste.length.toString().padLeft(2, '0');
                  final mot = liste.length > 1 ? 'réservations' : 'réservation';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$n $mot',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.texteSecondaire),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 70),
                          itemCount: liste.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = liste[i];
                            return ReservationCard(
                              reservation: r,
                              onDetails: () {
                                if (r.type == TypeRessource.materiel) {
                                  Get.to(() => MaterielDetailPage(id: r.id));
                                } else {
                                  Get.to(() => SalleDetailPage(id: r.id));
                                }
                              },
                              onLiberer: () {
                                c.liberer(r);
                                Get.snackbar(
                                  'Libérée',
                                  '${r.nom} a été libérée',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _EtatVide extends StatelessWidget {
  final VoidCallback? onReserver;

  const _EtatVide({this.onReserver});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 72, color: AppColors.texteSecondaire),
          const SizedBox(height: 12),
          const Text(
            'Aucune réservation pour le moment',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Faites-en une pour la voir ici',
            style: TextStyle(fontSize: 11, color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onReserver,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vert,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const Text('Réserver une salle',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
