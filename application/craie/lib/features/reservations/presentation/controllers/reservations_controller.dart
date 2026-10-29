import 'package:craie/core/utils/ui.dart';
import 'package:craie/features/resources/data/repositories/resource_repository.dart';
import 'package:craie/network/api_exception.dart';
import 'package:get/get.dart';

import '../../../../shared/services/session_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../resources/data/models/resource_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../data/models/reservation_model.dart';
import '../../data/repositories/reservation_repository.dart';

/// List of reservations. A responsable only sees their own; the
/// gestionnaire sees every attribution.
class ReservationsController extends GetxController {
  final ReservationRepository repository;

  ReservationsController(this.repository);

  final filter = 0.obs; // 0 all, 1 equipment, 2 rooms
  final query = ''.obs;

  List<ReservationModel> get items {
    final user = Get.find<SessionService>().currentUser.value;
    final mineOnly = user?.role == UserRole.responsableFiliere;
    final q = query.value.toLowerCase();
    return repository.reservations.where((r) {
      if (mineOnly && r.userId != user?.id) return false;
      if (filter.value == 1 && r.resource.type != ResourceType.equipment) return false;
      if (filter.value == 2 && r.resource.type != ResourceType.room) return false;
      return r.resource.name.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> release(ReservationModel r) async {
    if (!await confirmRelease(r.resource)) return;
    try {
      await repository.release(r);
      await Get.find<ResourceRepository>().load();
    } on ApiException catch (e) {
      showMessage('Erreur', e.message);
    }
  }

}

Future<bool> confirmRelease(ResourceModel resource) => showConfirmDialog(
      title: resource.isRoom ? 'Libérer la salle?' : 'Libérer le matériel?',
      message: resource.isRoom
          ? 'La salle ${resource.name.replaceFirst(RegExp('^Salle ', caseSensitive: false), '')} redevient disponible pour les autres filières.'
          : '${resource.name} redevient disponible pour les autres filières.',
      confirmLabel: resource.isRoom ? 'Libérer la salle' : 'Libérer le matériel',
    );
