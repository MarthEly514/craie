import 'package:get/get.dart';

import '../data/mock_data.dart';
import '../data/models/reservation.dart';
import 'materiel_controller.dart';
import 'salles_controller.dart';

class ReservationsController extends GetxController {
  final reservations = <Reservation>[].obs;
  final filtre = 'Toutes'.obs; // Toutes | Matériel | Salles
  final recherche = ''.obs;

  @override
  void onInit() {
    super.onInit();
    reservations.assignAll(reservationsDemo);
  }

  List<Reservation> get affichees {
    final q = recherche.value.trim().toLowerCase();
    return reservations.where((r) {
      final okFiltre = filtre.value == 'Toutes' ||
          (filtre.value == 'Salles' && r.type == TypeRessource.salle) ||
          (filtre.value == 'Matériel' && r.type == TypeRessource.materiel);
      final okRecherche = q.isEmpty ||
          r.nom.toLowerCase().contains(q) ||
          r.sousTitre.toLowerCase().contains(q);
      return okFiltre && okRecherche;
    }).toList();
  }

  void ajouter(Reservation r) {
    reservations.removeWhere((x) => x.id == r.id);
    reservations.insert(0, r);
  }

  void retirerParId(String id) => reservations.removeWhere((r) => r.id == id);

  void liberer(Reservation r) {
    reservations.remove(r);
    if (r.type == TypeRessource.salle) {
      if (Get.isRegistered<SallesController>()) {
        Get.find<SallesController>().marquerLibre(r.id);
      }
    } else {
      if (Get.isRegistered<MaterielController>()) {
        Get.find<MaterielController>().marquerLibre(r.id);
      }
    }
  }
}
