import 'package:get/get.dart';

import '../../../../shared/services/session_service.dart';
import '../../../resources/data/repositories/resource_repository.dart';
import '../../data/repositories/reservation_repository.dart';
import '../controllers/resource_detail_controller.dart';

class ResourceDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ResourceDetailController(
          Get.find<ResourceRepository>(),
          Get.find<ReservationRepository>(),
          Get.find<SessionService>(),
        ));
  }
}
