import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_slot.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/map_preview.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/time_range_field.dart';
import '../../../resources/data/models/availability.dart';
import '../../data/models/reservation_model.dart';
import '../controllers/resource_detail_controller.dart';

class ResourceDetailView extends GetView<ResourceDetailController> {
  const ResourceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final res = controller.resource;
    return Scaffold(
      appBar: AppBar(
        title: Text(res.isRoom ? 'Salles' : 'Matériels',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Obx(() {
              final list = controller.resourceReservations;
              final full = controller.availability == Availability.full;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  if (res.isRoom) _roomInfo() else _equipmentState(),
                  if (list.isNotEmpty) ..._reservationList(list),
                  if (!controller.isGestionnaire) _takenSlots(), // anonymous slots of everyone
                  if (full)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("Aucun créneau libre pour aujourd'hui.",
                          style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    )
                  else ...[
                    _sectionLabel('Créneau de réservation'),
                    _slot(context),
                    const SizedBox(height: 16),
                    if (controller.isGestionnaire) _field('Classe', 'Licence 2 GL', controller.classe),
                    _field('Motif', 'Cours de bases de donnees', controller.motif),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Réserver',
                      onPressed: res.isBroken || controller.timeError.value != null ? null : controller.book,
                    ),
                  ],
                  if (controller.isGestionnaire) ...[
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Supprimer la ressource',
                      style: AppButtonStyle.outlineDanger,
                      onPressed: controller.deleteResource,
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final res = controller.resource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(res.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (res.isRoom)
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(res.subtitle, style: const TextStyle(fontSize: 11)),
            ],
          )
        else
          Text(res.description, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _roomInfo() {
    final res = controller.resource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final a in res.amenities)
              Chip(
                label: Text(a),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                backgroundColor: const Color(0xFFE4E6DF),
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),
          ],
        ),
        _sectionLabel('Localisation Maps'),
        MapPreview(room: res),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _equipmentState() {
    final broken = controller.resource.isBroken;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Expanded(
            child: Text('Etat du matériel :',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          StatusBadge(label: broken ? 'En panne' : 'Bon', positive: !broken),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _slot(BuildContext context) => TimeRangeField(
    start: controller.start.value,
    end: controller.end.value,
    onPickStart: () => controller.pickTime(context, true),
    onPickEnd: () => controller.pickTime(context, false),
    errorText: controller.timeError.value,
  );

  Widget _field(String label, String hint, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: CustomTextField(controller: c, label: label, hint: hint),
  );

  List<Widget> _reservationList(List<ReservationModel> list) => [
    _sectionLabel(controller.isGestionnaire ? 'Réservations en cours' : 'Mes réservations'),
    for (final r in list)
      _ReservationRow(
        reservation: r,
        showOwner: controller.isGestionnaire,
        onRelease: controller.canReleaseReservation(r)
            ? () => controller.releaseReservation(r)
            : null,
      ),
    const SizedBox(height: 12),
  ];

  // here we could add the unavailable time slots so the user already knows what to do
  Widget _takenSlots() {
    final taken = controller.takenSlots;
    if (taken.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Créneaux déjà occupés'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in taken)
                Chip(
                  label: Text('${formatHm(s.start)} – ${formatHm(s.end)}'),
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
                  backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReservationRow extends StatelessWidget {
  final ReservationModel reservation;
  final bool showOwner;
  final VoidCallback? onRelease;

  const _ReservationRow({required this.reservation, required this.showOwner, this.onRelease});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${formatHm(r.slot.start)} – ${formatHm(r.slot.end)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if (showOwner)
                  Text('${r.userName} · ${r.classe}', style: const TextStyle(fontSize: 11)),
                Text(r.motif, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          if (onRelease != null)
            TextButton(
              onPressed: onRelease,
              child: const Text('Libérer', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
    );
  }
}
