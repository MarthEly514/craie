import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/services/session_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/filter_chips.dart';
import '../../../../shared/widgets/role_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/reservation_model.dart';
import '../controllers/reservations_controller.dart';

/// "Réservations" (responsable) / "Attributions" (gestionnaire).
class ReservationsPage extends GetView<ReservationsController> {
  final String title;

  const ReservationsPage({super.key, required this.title});

  static const _filters = ['Toutes', 'Matériel', 'Salles'];

  bool get _isGest =>
      Get.find<SessionService>().currentUser.value?.role == UserRole.gestionnaire;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isGest
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed(AppRoutes.assign),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('Attribuer', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SearchField(onChanged: (v) => controller.query.value = v),
            const SizedBox(height: 14),
            Obx(() => FilterChipsRow(
                  labels: _filters,
                  selected: controller.filter.value,
                  onSelected: (i) => controller.filter.value = i,
                )),
            const SizedBox(height: 12),
            Expanded(child: Obx(_list)),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final list = controller.items;
    if (list.isEmpty) {
      return _isGest
          ? EmptyState(
              title: 'Aucune attribution pour le moment',
              subtitle: 'Faites-en une pour la voir ici',
              buttonLabel: 'Attribuer une salle',
              onPressed: () => Get.toNamed(AppRoutes.assign),
            )
          : EmptyState(
              title: 'Aucune réservation pour le moment',
              subtitle: 'Faites-en une pour la voir ici',
              buttonLabel: 'Réserver une salle',
              onPressed: () => Get.find<NavController>().index.value = 1,
            );
    }
    final count = list.length.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$count ${_isGest ? 'attributions' : 'réservations'}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ReservationTile(reservation: list[i]),
          ),
        ),
      ],
    );
  }
}

class _ReservationTile extends GetView<ReservationsController> {
  final ReservationModel reservation;

  const _ReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation.resource;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (r.isRoom)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                ),
              Flexible(child: Text(r.subtitle, style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(AppRoutes.resourceDetail, arguments: r.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.dark, width: 1.2),
                  ),
                  child: const Text('Détails',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => controller.release(reservation),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Libérer',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
