import 'package:craie/shared/services/storage_service.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  /// Number of intro slides; the page after them is the role picker.
  static const int slideCount = 3;

  final page = 0.obs;
  final selectedRole = 0.obs;

  bool get isRolePage => page.value >= slideCount;

  void next() {
    if (page.value < slideCount) page.value++;
  }

  void skip() => page.value = slideCount;

  void goToLogin() {
    Get.find<StorageService>().setOnboardingDone();
    Get.offNamed(AppRoutes.login);
  } 
}
