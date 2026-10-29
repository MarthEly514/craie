import 'package:get/get.dart';

import '../../../reservations/data/repositories/reservation_repository.dart';
import '../../../reservations/presentation/controllers/reservations_controller.dart';
import '../../data/models/resource_model.dart';
import '../../data/repositories/resource_repository.dart';
import '../controllers/resource_list_controller.dart';

/// Gestionnaire home: resources tab + attributions tab.
class ResourcesBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<ResourceRepository>().load();
    Get.find<ReservationRepository>().load();
    Get.lazyPut(
      () => ResourceListController(Get.find<ResourceRepository>(),
          Get.find<ReservationRepository>(), ResourceType.room),
      tag: 'manage',
    );
    Get.lazyPut(() => ReservationsController(Get.find()));
  }
}
