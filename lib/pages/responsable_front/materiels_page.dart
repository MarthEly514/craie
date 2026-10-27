import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'materiel_detail_page.dart';

import '../../controllers/materiel_controller.dart';
import '../../core/app_theme.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/resource_card.dart';
import '../../widgets/search_field.dart';

class MaterielsPage extends StatelessWidget {
  const MaterielsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MaterielController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Matériel',
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
                  labels: const ['Tous', 'Rallonges', 'Projecteurs'],
                  selected: c.filtre.value,
                  onSelected: (l) => c.filtre.value = l,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final liste = c.affiches;

                  if (liste.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun matériel trouvé',
                        style:
                            TextStyle(fontSize: 14, color: AppColors.discret),
                      ),
                    );
                  }

                  final n = liste.length.toString().padLeft(2, '0');
                  final mot = liste.length > 1
                      ? 'matériels trouvés'
                      : 'matériel trouvé';

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
                            final m = liste[i];
                            return ResourceCard(
                              titre: m.nom,
                              sousTitre: m.reference,
                              libre: m.estLibre,
                              onTap: (m.estLibre || m.parMoi)
                                  ? () =>
                                      Get.to(() => MaterielDetailPage(id: m.id))
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
