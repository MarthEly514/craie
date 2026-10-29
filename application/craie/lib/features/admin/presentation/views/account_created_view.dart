import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';

class AccountCreatedView extends StatelessWidget {
  const AccountCreatedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Compte crée avec\nsucces',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Retour',
                style: AppButtonStyle.dark,
                onPressed: Get.back,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Creer un nouveau',
                style: AppButtonStyle.surface,
                onPressed: () => Get.offNamed(AppRoutes.adminCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
