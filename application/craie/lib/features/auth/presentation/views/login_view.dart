import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Connexion',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 28),
                  CustomTextField(
                    controller: controller.identifierController,
                    label: 'Identifiant',
                    hint: 'Votre identifiant',
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  Obx(() => CustomTextField(
                        controller: controller.passwordController,
                        label: 'Mot de passe',
                        hint: '••••••••',
                        obscureText: controller.obscure.value,
                        validator: Validators.required,
                        suffix: IconButton(
                          icon: Icon(
                            controller.obscure.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted,
                          ),
                          onPressed: () => controller.obscure.toggle(),
                        ),
                      )),
                  const SizedBox(height: 20),
                  Obx(() => PrimaryButton(
                              label: 'Connexion',
                              loading: controller.isLoading.value,
                              onPressed: controller.login,
                            )),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
