import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_slot.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/map_preview.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/time_range_field.dart';
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
              final r = controller.reservation;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  if (res.isRoom) _roomInfo() else _equipmentState(),
                  _sectionLabel('Crénau de réservation'),
                  _slot(context, r),
                  const SizedBox(height: 16),
                  if (controller.isGestionnaire) _field('Classe', 'Licence 2 GL', controller.classe, r?.classe),
                  _field('Motif', 'Cours de bases de donnees', controller.motif, r?.motif),
                  const SizedBox(height: 8),
                  ..._actions(r),
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

  Widget _slot(BuildContext context, ReservationModel? r) {
    if (r != null) {
      return TimeRangeField(
        start: TimeOfDay.fromDateTime(r.slot.start),
        end: TimeOfDay.fromDateTime(r.slot.end),
      );
    }
    return TimeRangeField(
      start: controller.start.value,
      end: controller.end.value,
      onPickStart: () => controller.pickTime(context, true),
      onPickEnd: () => controller.pickTime(context, false),
      errorText: controller.timeError.value,
    );
  }

  /// Editable field when free, plain read-only text when reserved.
  Widget _field(String label, String hint, TextEditingController c, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: value == null
          ? CustomTextField(controller: c, label: label, hint: hint)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
    );
  }

  List<Widget> _actions(ReservationModel? r) {
    final res = controller.resource;
    if (r == null) {
      return [
        PrimaryButton(
          label: 'Réserver',
          onPressed: res.isBroken || controller.timeError.value != null ? null : controller.book,
        ),
        if (controller.isGestionnaire) ...[
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Supprimer la ressource',
            style: AppButtonStyle.outlineDanger,
            onPressed: controller.deleteResource,
          ),
        ],
      ];
    }
    return [
      if (controller.canRelease) ...[
        PrimaryButton(label: 'Libérer', style: AppButtonStyle.dark, onPressed: controller.release),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '${res.isRoom ? 'La salle sera automatiquement libérée' : 'Le matériel sera automatiquement libéré'}\napres echeance',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ),
      ] else
        Center(
          child: Text('Réservé par ${r.userName} jusqu\'à ${formatHm(r.slot.end)}',
              style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ),
    ];
  }
}
