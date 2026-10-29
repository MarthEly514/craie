import 'package:craie/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends GetxController {
  final AuthRepository repository;

  LoginController(this.repository);

  final formKey = GlobalKey<FormState>();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  final obscure = true.obs;
  final isLoading = false.obs;

  Future<void> login() async {
    if (!formKey.currentState!.validate() || isLoading.value) return;
    isLoading.value = true;
    try {
      final user = await repository.login(
        identifierController.text,
        passwordController.text,
      );
      Get.offAllNamed(AppRoutes.homeFor(user.role));
    } on ApiException catch (e) {
      Get.snackbar('Connexion impossible', e.message,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } finally {
      isLoading.value = false;
    }
  }


  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
