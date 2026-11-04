import 'package:get/get.dart';

import '../../features/resources/data/repositories/resource_repository.dart';
import '../../features/reservations/data/repositories/reservation_repository.dart';
import '../../network/api_client.dart';
import '../../shared/services/session_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

/// App-wide singletons.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SessionService(), permanent: true);
    Get.put(ApiClient(), permanent: true);
    final api = Get.find<ApiClient>();
    final session = Get.find<SessionService>();
    Get.put(AuthRepository(api, session),permanent: true,);
    Get.put(ResourceRepository(api), permanent: true);
    Get.put(ReservationRepository(api), permanent: true);

  }
}
