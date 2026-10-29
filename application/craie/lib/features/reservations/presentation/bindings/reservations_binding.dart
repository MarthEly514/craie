import 'package:get/get.dart';

import '../../../resources/data/models/resource_model.dart';
import '../../../resources/data/repositories/resource_repository.dart';
import '../../../resources/presentation/controllers/resource_list_controller.dart';
import '../../data/repositories/reservation_repository.dart';
import '../controllers/reservations_controller.dart';

/// Responsable home: reservations, rooms, equipment.
class ReservationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ReservationsController(Get.find<ReservationRepository>()));
    for (final (tag, type) in [
      ('room', ResourceType.room),
      ('equipment', ResourceType.equipment),
    ]) {
      Get.lazyPut(
        () => ResourceListController(Get.find<ResourceRepository>(),
            Get.find<ReservationRepository>(), type),
        tag: tag,
      );
    }
  }
}
