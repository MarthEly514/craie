import 'package:get/get.dart';

import '../../../resources/data/models/resource_model.dart';
import '../../../resources/data/repositories/resource_repository.dart';
import '../../../resources/presentation/controllers/resource_list_controller.dart';
import '../../data/repositories/reservation_repository.dart';

class AssignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ResourceListController(Get.find<ResourceRepository>(),
          Get.find<ReservationRepository>(), ResourceType.room),
      tag: 'assign',
    );
  }
}
