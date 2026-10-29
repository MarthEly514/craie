import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _slides = [
    ('assets/images/onboarding_1.png', 'Toutes vos salles\nà portée de clic'),
    ('assets/images/onboarding_2.png', 'Réservez ce qu\'il\nvous faut'),
    ('assets/images/onboarding_3.png', 'Sans conflit ou\ndoute'),
  ];

  static const _roles = [
    ('assets/images/role_gest.png', 'Gestionnaire de\nmatériel'),
    ('assets/images/role_resp.png', 'Responsable de\nfilière'),
    ('assets/images/role_admin.png', 'Administrateur\nSysteme'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(() => controller.isRolePage ? _rolePage() : _slidePage()),
        ),
      ),
    );
  }

  Widget _slidePage() {
    final i = controller.page.value;
    final (image, title) = _slides[i];
    final last = i == OnboardingController.slideCount - 1;
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            for (var s = 0; s < OnboardingController.slideCount; s++) ...[
              if (s > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: s <= i ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
        Expanded(child: Center(child: Image.asset(image, height: 260))),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 36),
        PrimaryButton(
          label: last ? 'C\'est parti' : 'Continuer',
          onPressed: controller.next,
        ),
        if (!last) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Passer',
            style: AppButtonStyle.surface,
            onPressed: controller.skip,
          ),
        ] else
          const SizedBox(height: 64),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _rolePage() {
    return Column(
      children: [
        const SizedBox(height: 56),
        const Text('Quel rôle vous\ndécrit le mieux ?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 28),
        for (var i = 0; i < _roles.length; i++)
          GestureDetector(
            onTap: () => controller.selectedRole.value = i,
            child: Container(
              height: 96,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: controller.selectedRole.value == i
                    ? AppColors.primaryLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  if (i != 1) ...[
                    Image.asset(_roles[i].$1, width: 70),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(_roles[i].$2,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  if (i == 1) Image.asset(_roles[i].$1, width: 64),
                ],
              ),
            ),
          ),
        const Spacer(),
        PrimaryButton(label: 'Me connecter', onPressed: controller.goToLogin),
        const SizedBox(height: 40),
      ],
    );
  }
}
