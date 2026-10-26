import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'barre_navigation.dart';
import 'couleurs.dart';

enum CategorieMateriel { rallonge, projecteur }

class Materiel {
  const Materiel({
    required this.nom,
    required this.detail,
    required this.categorie,
    required this.libre,
  });

  final String nom;
  final String detail;
  final CategorieMateriel categorie;
  final bool libre;
}

class MaterielController extends GetxController {
  // Données factices en attendant le mode de stockage choisi par l'enseignant.
  final materiels = <Materiel>[
    const Materiel(
      nom: 'Projecteur Acer514',
      detail: 'Acer514-12V_610',
      categorie: CategorieMateriel.projecteur,
      libre: true,
    ),
    const Materiel(
      nom: 'Rallonge_1',
      detail: 'Rallonge 12m',
      categorie: CategorieMateriel.rallonge,
      libre: true,
    ),
    const Materiel(
      nom: 'Projecteur EpsonP6',
      detail: 'Epson P6-A58',
      categorie: CategorieMateriel.projecteur,
      libre: false,
    ),
    const Materiel(
      nom: 'Rallonge_3',
      detail: 'Rallonge 16m',
      categorie: CategorieMateriel.rallonge,
      libre: false,
    ),
  ].obs;

  final recherche = ''.obs;
  final filtre = Rxn<CategorieMateriel>(); // null = Tous

  List<Materiel> get visibles {
    final q = recherche.value.trim().toLowerCase();
    return materiels.where((m) {
      final okCategorie = filtre.value == null || m.categorie == filtre.value;
      final okTexte = q.isEmpty ||
          m.nom.toLowerCase().contains(q) ||
          m.detail.toLowerCase().contains(q);
      return okCategorie && okTexte;
    }).toList();
  }
}

class MaterielPage extends StatelessWidget {
  const MaterielPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MaterielController());

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
                    'Matériel',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ChampRecherche(onChanged: (v) => c.recherche.value = v),
                  const SizedBox(height: 18),
                  Obx(() => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _Filtre(
                              label: 'Tous',
                              actif: c.filtre.value == null,
                              onTap: () => c.filtre.value = null,
                            ),
                            const SizedBox(width: 10),
                            _Filtre(
                              label: 'Rallonges',
                              actif: c.filtre.value ==
                                  CategorieMateriel.rallonge,
                              onTap: () =>
                                  c.filtre.value = CategorieMateriel.rallonge,
                            ),
                            const SizedBox(width: 10),
                            _Filtre(
                              label: 'Projecteurs',
                              actif: c.filtre.value ==
                                  CategorieMateriel.projecteur,
                              onTap: () =>
                                  c.filtre.value = CategorieMateriel.projecteur,
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Obx(() {
                    final n = c.visibles.length;
                    return Text(
                      '${n.toString().padLeft(2, '0')} matériel${n > 1 ? 's' : ''} trouvé${n > 1 ? 's' : ''}',
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
                            'Aucun matériel trouvé',
                            style: TextStyle(color: Couleurs.discret),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: liste.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            _CarteMateriel(materiel: liste[i]),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  BarreNavigation(
                    indexActif: 2,
                    onTap: (i) {
                      // TODO : brancher la navigation (Get.offAll, routes, etc.)
                      // une fois les autres pages disponibles.
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

class _CarteMateriel extends StatelessWidget {
  const _CarteMateriel({required this.materiel});

  final Materiel materiel;

  @override
  Widget build(BuildContext context) {
    // Un matériel pris est affiché estompé, comme sur la maquette.
    return Opacity(
      opacity: materiel.libre ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
        decoration: BoxDecoration(
          color: Couleurs.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materiel.nom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    materiel.detail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Couleurs.discret,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Statut(libre: materiel.libre),
          ],
        ),
      ),
    );
  }
}

class _Statut extends StatelessWidget {
  const _Statut({required this.libre});

  final bool libre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: libre
            ? Couleurs.lime.withAlpha(140)
            : Couleurs.corail.withAlpha(50),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        libre ? 'Libre' : 'Prise',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: libre ? Colors.black : Couleurs.discret,
        ),
      ),
    );
  }
}