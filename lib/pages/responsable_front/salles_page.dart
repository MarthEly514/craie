import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/salles_controller.dart';
import '../../core/app_theme.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/resource_card.dart';
import '../../widgets/search_field.dart';
import 'salle_detail_page.dart';

class SallesPage extends StatelessWidget {
  const SallesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SallesController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salles',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.encre,
                ),
              ),
              const SizedBox(height: 16),
              SearchField(onChanged: (v) => c.recherche.value = v),
              const SizedBox(height: 12),
              Obx(
                () => FilterChips(
                  labels: const ['Toutes', 'Iran', 'Zone master'],
                  selected: c.filtre.value,
                  onSelected: (l) => c.filtre.value = l,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final liste = c.affichees;

                  if (liste.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune salle trouvée',
                        style:
                            TextStyle(fontSize: 14, color: AppColors.discret),
                      ),
                    );
                  }

                  final n = liste.length.toString().padLeft(2, '0');
                  final mot =
                      liste.length > 1 ? 'salles trouvées' : 'salle trouvée';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$n $mot',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.discret),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: liste.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final s = liste[i];
                            return ResourceCard(
                              titre: s.nom,
                              sousTitre: s.lieu,
                              libre: s.estLibre,
                              avecPin: true,
                              onTap: (s.estLibre || s.parMoi)
                                  ? () => Get.to(
                                      () => SalleDetailPage(id: s.id))
                                  : null,
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