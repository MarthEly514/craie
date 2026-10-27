import 'package:get/get.dart';

import '../data/models/reservation.dart';
import '../data/models/salle.dart';
import '../data/salles_data.dart';
import 'reservations_controller.dart';

class SallesController extends GetxController {
  final salles = <Salle>[].obs;
  final filtre = 'Toutes'.obs; // Toutes | Iran | Zone master
  final recherche = ''.obs;

  @override
  void onInit() {
    super.onInit();
    salles.assignAll(sallesDemo);
  }

  List<Salle> get affichees {
    final q = recherche.value.trim().toLowerCase();
    return salles.where((s) {
      final okFiltre = filtre.value == 'Toutes' || s.zone == filtre.value;
      final okRecherche = q.isEmpty ||
          s.nom.toLowerCase().contains(q) ||
          s.lieu.toLowerCase().contains(q);
      return okFiltre && okRecherche;
    }).toList();
  }

  Salle parId(String id) => salles.firstWhere((s) => s.id == id);

  void _remplacer(String id, Salle Function(Salle) f) {
    final i = salles.indexWhere((s) => s.id == id);
    if (i == -1) return;
    salles[i] = f(salles[i]);
  }

  void reserver(
    String id, {
    required String debut,
    required String fin,
    required String motif,
  }) {
    final s = parId(id);
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
          nom: s.nom,
          sousTitre: '${s.lieu} · $debut - $fin',
          type: TypeRessource.salle,
        ),
      );
    }
  }

  /// Libération depuis la fiche de détail.
  void liberer(String id) {
    marquerLibre(id);
    if (Get.isRegistered<ReservationsController>()) {
      Get.find<ReservationsController>().retirerParId(id);
    }
  }

  /// Remet la salle à « Libre » (aussi appelé depuis l'onglet Réservations).
  void marquerLibre(String id) {
    _remplacer(
      id,
      (x) => Salle(
        id: x.id,
        nom: x.nom,
        zone: x.zone,
        lieu: x.lieu,
        equipements: x.equipements,
        estLibre: true,
      ),
    );
  }
}