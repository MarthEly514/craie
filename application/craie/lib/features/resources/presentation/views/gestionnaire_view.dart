import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/profile_view.dart';
import '../../../../shared/widgets/role_shell.dart';
import '../../../reservations/presentation/views/reservations_page.dart';
import '../../data/models/resource_model.dart';
import '../controllers/resource_list_controller.dart';
import '../widgets/resource_list_body.dart';

/// Gestionnaire home: Ressources / Attributions / Profil.
class GestionnaireView extends StatelessWidget {
  const GestionnaireView({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleShell(
      pages: [ResourcesPage(), ReservationsPage(title: 'Attributions'), ProfileView()],
      icons: [Icons.apartment_outlined, Icons.bookmark_added_outlined, Icons.person_outline],
    );
  }
}

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ResourceListController>(tag: 'manage');
    return Scaffold(
      floatingActionButton: Obx(() => c.ofType.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: () => Get.toNamed(c.type.value == ResourceType.room
                  ? AppRoutes.newRoom
                  : AppRoutes.newEquipment),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
      body: ResourceListBody(
        controller: c,
        title: 'Ressources',
        manage: true,
        switchable: true,
      ),
    );
  }
}
