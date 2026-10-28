import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'barre_navigation.dart';
import 'couleurs.dart';

class ProfilController extends GetxController {
  // Données factices en attendant le mode de stockage choisi par l'enseignant.
  final nomComplet = 'Miguel MIGAN'.obs;
  final role = 'Responsable (IM-2)'.obs;

  void seDeconnecter() {
    Get.snackbar(
      'Déconnexion',
      'Vous avez été déconnecté',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
    // TODO : quand la page de connexion existera, la relier ici :
    // Get.offAll(() => const ConnexionPage());
  }
}

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfilController());

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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Informations personnelles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Le rond avec l'icône de personne
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Couleurs.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 48,
                              color: Couleurs.discret,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // La carte avec le nom et le rôle
                          Obx(() => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Couleurs.surface,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _Etiquette('Nom complet'),
                                    const SizedBox(height: 6),
                                    _Valeur(c.nomComplet.value),
                                    const SizedBox(height: 20),
                                    const _Etiquette('Role'),
                                    const SizedBox(height: 6),
                                    _Valeur(c.role.value),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 70),
                          // Le bouton rouge « Se déconnecter »
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: c.seDeconnecter,
                              style: ElevatedButton.styleFrom(
                                // rose de la maquette
                                backgroundColor: const Color(0xFFFF8E8E),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'Se déconnecter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const BarreNavigation(indexActif: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Petit titre en gras (« Nom complet », « Role »)
class _Etiquette extends StatelessWidget {
  const _Etiquette(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }
}

// Texte gris sous le titre
class _Valeur extends StatelessWidget {
  const _Valeur(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: const TextStyle(
        fontSize: 16,
        color: Couleurs.discret,
      ),
    );
  }
}