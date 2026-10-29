import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/filter_chips.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/segmented_pills.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/resource_model.dart';
import '../controllers/resource_list_controller.dart';

/// Search + (type switch) + filters + list of resources.
///
/// [manage] = gestionnaire's Ressources tab (delete icons, "Lieu"/"Type"
/// filter, empty state). Otherwise rows show Libre / Prise.
class ResourceListBody extends StatelessWidget {
  final ResourceListController controller;
  final String title;
  final bool manage;
  final bool switchable;

  const ResourceListBody({
    super.key,
    required this.controller,
    required this.title,
    this.manage = false,
    this.switchable = false,
  });

  bool get _rooms => controller.type.value == ResourceType.room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SearchField(onChanged: (v) => controller.query.value = v),
          const SizedBox(height: 14),
          if (switchable) ...[
            Obx(() => SegmentedPills(
                  labels: const ['Salles', 'Matériel'],
                  selected: _rooms ? 0 : 1,
                  onChanged: (i) => controller.setType(
                      i == 0 ? ResourceType.room : ResourceType.equipment),
                )),
            const SizedBox(height: 14),
          ],
          Obx(() => manage ? _manageChips(context) : _browseChips()),
          const SizedBox(height: 12),
          Expanded(child: Obx(_list)),
        ],
      ),
    );
  }

  // "Toutes" + "Lieu"/"Type" (opens a picker)
  Widget _manageChips(BuildContext context) {
    final active = controller.filter.value;
    return Row(
      children: [
        AppChip(
          label: _rooms ? 'Toutes' : 'Tous',
          selected: active == null,
          onTap: () => controller.filter.value = null,
        ),
        const SizedBox(width: 8),
        AppChip(
          label: active ?? (_rooms ? 'Lieu' : 'Type'),
          selected: active != null,
          onTap: () => _pickFilter(context),
        ),
      ],
    );
  }

  void _pickFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in controller.options)
              ListTile(
                title: Text(o),
                onTap: () {
                  controller.filter.value = o;
                  Get.back();
                },
              ),
          ],
        ),
      ),
    );
  }

  // "Toutes" + one chip per zone / category
  Widget _browseChips() {
    final options = controller.options;
    final active = controller.filter.value;
    final selected = active == null ? 0 : options.indexOf(active) + 1;
    return FilterChipsRow(
      labels: [_rooms ? 'Toutes' : 'Tout', ...options],
      selected: selected < 0 ? 0 : selected,
      onSelected: (i) => controller.filter.value = i == 0 ? null : options[i - 1],
    );
  }

  Widget _list() {
    final list = controller.items;
    final noun = _rooms ? 'salles' : 'matériels';

    if (manage && controller.ofType.isEmpty) {
      return EmptyState(
        title: _rooms ? 'Aucune salle pour le moment' : 'Aucun matériel pour le moment',
        subtitle: _rooms ? 'Ajoutez-en une pour la voir ici' : 'Ajoutez-en un pour les voir ici',
        buttonLabel: _rooms ? 'Ajouter une salle' : 'Ajouter un matériel',
        onPressed: () => Get.toNamed(_rooms ? AppRoutes.newRoom : AppRoutes.newEquipment),
      );
    }

    final count = list.length.toString().padLeft(2, '0');
    final label = manage
        ? '$count $noun'
        : '$count $noun ${_rooms ? 'trouvées' : 'trouvés'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ResourceTile(
              resource: list[i],
              taken: controller.isTaken(list[i]),
              manage: manage,
              onDelete: () async {
                final ok = await showConfirmDialog(
                  title: 'Supprimer la ressource?',
                  message:
                      '${list[i].name} sera supprimé définitivement. Ses réservations en cours seront libérées.',
                  confirmLabel: 'Supprimer définitivement',
                  danger: true,
                );
                if (ok) controller.remove(list[i]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final ResourceModel resource;
  final bool taken;
  final bool manage;
  final VoidCallback onDelete;

  const _ResourceTile({
    required this.resource,
    required this.taken,
    required this.manage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final faded = !manage && taken;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Get.toNamed(AppRoutes.resourceDetail, arguments: resource.id),
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 12, manage ? 6 : 14, 12),
        decoration: BoxDecoration(
          color: faded ? const Color(0xFFF8F9F6) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: faded ? 0.5 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (resource.isRoom)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.muted),
                          ),
                        Flexible(
                          child: Text(resource.subtitle,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (manage)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              )
            else if (resource.isBroken)
              const StatusBadge(label: 'En panne', positive: false)
            else
              StatusBadge(label: taken ? 'Prise' : 'Libre', positive: !taken),
          ],
        ),
      ),
    );
  }
}
