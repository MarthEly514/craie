import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'barre_navigation.dart';
import 'couleurs.dart';

class Salle {
  const Salle({
    required this.nom,
    required this.zone,
    required this.lieu,
    required this.libre,
  });

  final String nom;
  final String zone; // sert au filtre (Iran, Zone master...)
  final String lieu; // texte affiché sous le nom
  final bool libre;
}

class SallesController extends GetxController {
  // Données factices en attendant le mode de stockage choisi par l'enseignant.
  final salles = <Salle>[
    const Salle(
      nom: 'Salle A2-2',
      zone: 'Zone master',
      lieu: 'Zone master (Zogbadjè)',
      libre: true,
    ),
    const Salle(
      nom: 'Salle A2-1',
      zone: 'Zone master',
      lieu: 'Zone master (Zogbadjè)',
      libre: true,
    ),
    const Salle(
      nom: 'Salle G2',
      zone: 'Zone master',
      lieu: 'Zone master (Zogbadjè)',
      libre: true,
    ),
    const Salle(
      nom: 'Salle F1',
      zone: 'Zone master',
      lieu: 'Zone master (Zogbadjè)',
      libre: false,
    ),
    const Salle(
      nom: 'Salle F2',
      zone: 'Zone master',
      lieu: 'Zone master (Zogbadjè)',
      libre: false,
    ),
  ].obs;

  final recherche = ''.obs;
  final zoneActive = RxnString(); // null = Toutes

  List<Salle> get visibles {
    final q = recherche.value.trim().toLowerCase();
    return salles.where((s) {
      final okZone = zoneActive.value == null || s.zone == zoneActive.value;
      final okTexte = q.isEmpty ||
          s.nom.toLowerCase().contains(q) ||
          s.lieu.toLowerCase().contains(q);
      return okZone && okTexte;
    }).toList();
  }
}

class SallesPage extends StatelessWidget {
  const SallesPage({super.key});

  static const _zones = ['Iran', 'Zone master'];

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SallesController());

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
                    'Salles',
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
                              label: 'Toutes',
                              actif: c.zoneActive.value == null,
                              onTap: () => c.zoneActive.value = null,
                            ),
                            for (final z in _zones) ...[
                              const SizedBox(width: 10),
                              _Filtre(
                                label: z,
                                actif: c.zoneActive.value == z,
                                onTap: () => c.zoneActive.value = z,
                              ),
                            ],
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Obx(() {
                    final n = c.visibles.length;
                    return Text(
                      '${n.toString().padLeft(2, '0')} salle${n > 1 ? 's' : ''} trouvée${n > 1 ? 's' : ''}',
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
                            'Aucune salle trouvée',
                            style: TextStyle(color: Couleurs.discret),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: liste.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _CarteSalle(salle: liste[i]),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const BarreNavigation(indexActif: 1),
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

class _CarteSalle extends StatelessWidget {
  const _CarteSalle({required this.salle});

  final Salle salle;

  @override
  Widget build(BuildContext context) {
    // Une salle prise est affichée estompée, comme sur la maquette.
    return Opacity(
      opacity: salle.libre ? 1 : 0.5,
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
                    salle.nom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 20, color: Couleurs.discret),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          salle.lieu,
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
            const SizedBox(width: 10),
            _Statut(libre: salle.libre),
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