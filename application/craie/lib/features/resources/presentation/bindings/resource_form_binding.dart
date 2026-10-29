import 'package:get/get.dart';

import '../../data/repositories/resource_repository.dart';
import '../controllers/resource_form_controller.dart';

class ResourceFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ResourceFormController(Get.find<ResourceRepository>()));
  }
}
