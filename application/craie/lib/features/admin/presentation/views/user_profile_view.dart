import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/profile_view.dart';
import '../../../auth/data/models/user_model.dart';
import '../controllers/admin_controller.dart';

/// "Profil utilisateur": details of a managed account + suspend / delete.
/// Route argument: the user id.
class UserProfileView extends GetView<AdminController> {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.find(Get.arguments as String)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil utilisateur',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          // Rebuilds when the account is suspended / reactivated.
          child: Obx(() {
            controller.repository.users.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informations personnelles',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.person_outline, size: 36, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                InfoCard(rows: [
                  ('Nom complet', user.name),
                  (
                    user.role == UserRole.responsableFiliere
                        ? 'Numero matricule'
                        : 'Adresse mail',
                    user.identifier
                  ),
                  ('Mot de passe', '••••••'),
                  ('Role', user.subtitle),
                ]),
                const Spacer(),
                PrimaryButton(
                  label: user.isSuspended ? 'Réactiver le compte' : 'Suspendre le compte',
                  style: AppButtonStyle.surface,
                  onPressed: () =>
                      user.isSuspended ? controller.reactivate(user) : controller.suspend(user),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Supprimer le compte',
                  style: AppButtonStyle.outlineDanger,
                  onPressed: () => controller.delete(user),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
