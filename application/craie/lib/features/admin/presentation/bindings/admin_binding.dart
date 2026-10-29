import 'package:craie/network/api_client.dart';
import 'package:get/get.dart';
import '../../data/repositories/admin_repository.dart';
import '../controllers/admin_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AdminController(Get.find<AdminRepository>()));
    Get.lazyPut(() => AdminRepository(Get.find<ApiClient>()));
    Get.lazyPut(() => AdminController(Get.find<AdminRepository>()));
  }
}
