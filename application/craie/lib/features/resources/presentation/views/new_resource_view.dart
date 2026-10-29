import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/resource_form_controller.dart';

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );

Widget _dropdown(String value, List<String> items, ValueChanged<String> onChanged) =>
    DropdownButtonFormField<String>(
      initialValue: value,
      style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: CustomTextField.border(),
        enabledBorder: CustomTextField.border(),
      ),
      items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
      onChanged: (v) => onChanged(v!),
    );

class NewRoomView extends GetView<ResourceFormController> {
  const NewRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Salle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: controller.name,
                  label: 'Nom de la salle',
                  hint: 'Salle A2-2',
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                _label('Batiment ou zone'),
                _dropdown(controller.zone.value, AppConstants.zones,
                    (v) => controller.zone.value = v),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller.location,
                  label: 'Emplacement',
                  hint: 'Zogbadjè',
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: controller.mapsUrl,
                  label: 'Localisation Maps (optionnel)',
                  hint: 'Coller le lien',
                ),
                const SizedBox(height: 12),
                Obx(() => Wrap(
                      spacing: 8,
                      children: [
                        for (final a in AppConstants.roomAmenities)
                          GestureDetector(
                            onTap: () => controller.toggleAmenity(a),
                            child: Chip(
                              label: Text(a),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: controller.amenities.contains(a)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              backgroundColor: controller.amenities.contains(a)
                                  ? Colors.black
                                  : AppColors.surface,
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                            ),
                          ),
                      ],
                    )),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Enregistrer la salle',
                  style: AppButtonStyle.dark,
                  onPressed: controller.saveRoom,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewEquipmentView extends GetView<ResourceFormController> {
  const NewEquipmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Matériel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: controller.name,
                  label: 'Nom du matériel',
                  hint: 'Canon 12A500',
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                _label('Type de materiel'),
                _dropdown(controller.category.value, AppConstants.equipmentTypes,
                    (v) => controller.category.value = v),
                const SizedBox(height: 16),
                _label('Courte description'),
                TextFormField(
                  controller: controller.description,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Projecteur UHD 4K',
                    hintStyle: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w600),
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.muted, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.muted, width: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Etat du matériel'),
                Obx(() => Row(
                      children: [
                        Expanded(child: _stateButton('Bon', !controller.isBroken.value,
                            () => controller.isBroken.value = false)),
                        const SizedBox(width: 12),
                        Expanded(child: _stateButton('En panne', controller.isBroken.value,
                            () => controller.isBroken.value = true)),
                      ],
                    )),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Enregistrer le matériel',
                  style: AppButtonStyle.dark,
                  onPressed: controller.saveEquipment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateButton(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.dark : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.dark),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.dark,
              )),
        ),
      );
}
