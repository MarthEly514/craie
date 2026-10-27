import 'package:get/get.dart';

import '../data/materiel_data.dart';
import '../data/models/materiel.dart';
import '../data/models/reservation.dart';
import 'reservations_controller.dart';

class MaterielController extends GetxController {
  final materiels = <Materiel>[].obs;
  final filtre = 'Tous'.obs; // Tous | Rallonges | Projecteurs
  final recherche = ''.obs;

  @override
  void onInit() {
    super.onInit();
    materiels.assignAll(materielsDemo);
  }

  List<Materiel> get affiches {
    final q = recherche.value.trim().toLowerCase();
    return materiels.where((m) {
      final okFiltre = filtre.value == 'Tous' ||
          (filtre.value == 'Rallonges' &&
              m.categorie == CategorieMateriel.rallonge) ||
          (filtre.value == 'Projecteurs' &&
              m.categorie == CategorieMateriel.projecteur);
      final okRecherche = q.isEmpty ||
          m.nom.toLowerCase().contains(q) ||
          m.reference.toLowerCase().contains(q);
      return okFiltre && okRecherche;
    }).toList();
  }

  Materiel parId(String id) => materiels.firstWhere((m) => m.id == id);

  void _remplacer(String id, Materiel Function(Materiel) f) {
    final i = materiels.indexWhere((m) => m.id == id);
    if (i == -1) return;
    materiels[i] = f(materiels[i]);
  }

  void reserver(
    String id, {
    required String debut,
    required String fin,
    required String motif,
  }) {
    final m = parId(id);
    _remplacer(
      id,
      (x) => x.copyWith(
        estLibre: false,
        parMoi: true,
        debut: debut,
        fin: fin,
        motif: motif,
      ),
    );

    if (Get.isRegistered<ReservationsController>()) {
      Get.find<ReservationsController>().ajouter(
        Reservation(
          id: id,
          nom: m.nom,
          sousTitre: '${m.reference} · $debut - $fin',
          type: TypeRessource.materiel,
        ),
      );
    }
  }

  /// Libération depuis la page de détail.
  void liberer(String id) {
    marquerLibre(id);
    if (Get.isRegistered<ReservationsController>()) {
      Get.find<ReservationsController>().retirerParId(id);
    }
  }

  /// Remet le matériel à « Libre » (aussi appelé depuis l'onglet Réservations).
  void marquerLibre(String id) {
    _remplacer(
      id,
      (x) => Materiel(
        id: x.id,
        nom: x.nom,
        reference: x.reference,
        categorie: x.categorie,
        etat: x.etat,
        estLibre: true,
      ),
    );
  }
}