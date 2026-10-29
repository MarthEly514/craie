import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/profile_view.dart';
import '../../../../shared/widgets/role_shell.dart';
import '../../../resources/presentation/controllers/resource_list_controller.dart';
import '../../../resources/presentation/widgets/resource_list_body.dart';
import 'reservations_page.dart';

/// Responsable home: Réservations / Salles / Matériel / Profil.
class ResponsableView extends StatelessWidget {
  const ResponsableView({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      pages: [
        const ReservationsPage(title: 'Réservations'),
        ResourceListBody(
          controller: Get.find<ResourceListController>(tag: 'room'),
          title: 'Salles',
        ),
        ResourceListBody(
          controller: Get.find<ResourceListController>(tag: 'equipment'),
          title: 'Matériel',
        ),
        const ProfileView(),
      ],
      icons: const [
        Icons.bookmark_added_outlined,
        Icons.apartment_outlined,
        Icons.videocam_outlined,
        Icons.person_outline,
      ],
    );
  }
}
