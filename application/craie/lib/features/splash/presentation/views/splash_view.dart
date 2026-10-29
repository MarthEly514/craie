import 'package:craie/features/auth/data/repositories/auth_repository.dart';
import 'package:craie/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../widgets/craie_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final restoring = Get.find<AuthRepository>().restoreSession();
    // The logo stays at least 2 seconds, even if the session is restored faster.
    await Future<void>.delayed(const Duration(seconds: 2));
    final user = await restoring;
    
    if (user != null) {
      Get.offAllNamed(AppRoutes.homeFor(user.role));
    } else if (Get.find<StorageService>().onboardingDone) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(child: CraieLogo()),
    );
  }
}
