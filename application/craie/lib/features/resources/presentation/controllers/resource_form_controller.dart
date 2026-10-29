import 'package:craie/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/ui.dart';
import '../../data/models/resource_model.dart';
import '../../data/repositories/resource_repository.dart';

/// State of the "Nouvelle salle" / "Nouveau matériel" forms.
class ResourceFormController extends GetxController {
  final ResourceRepository repository;

  ResourceFormController(this.repository);

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final location = TextEditingController();
  final mapsUrl = TextEditingController();
  final description = TextEditingController();

  final zone = AppConstants.zones.first.obs;
  final category = AppConstants.equipmentTypes.first.obs;
  final amenities = <String>{}.obs;
  final isBroken = false.obs;

  void toggleAmenity(String a) {
    amenities.contains(a) ? amenities.remove(a) : amenities.add(a);
  }

  Future<void> saveRoom() async {
    if (!formKey.currentState!.validate()) return;
    try {
      await repository.add(ResourceModel(
        id: '',
        name: name.text.trim(),
        type: ResourceType.room,
        zone: zone.value,
        location: location.text.trim(),
        mapsUrl: mapsUrl.text.trim().isEmpty ? null : mapsUrl.text.trim(),
        amenities: amenities.toList(),
      ));
      Get.back();
      showMessage('Salle enregistrée', name.text.trim());
    } on ApiException catch (e) {
      showMessage('Erreur', e.message);
    } 
  }

  Future<void> saveEquipment() async {
    if (!formKey.currentState!.validate()) return;
    try {
      await repository.add(ResourceModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        type: ResourceType.equipment,
        category: category.value,
        description: description.text.trim(),
        isBroken: isBroken.value,
      ));
      Get.back();
      showMessage('Matériel enregistré', name.text.trim());
    } on ApiException catch (e) {
      showMessage('Erreur', e.message);
    } 
  }

  @override
  void onClose() {
    name.dispose();
    location.dispose();
    mapsUrl.dispose();
    description.dispose();
    super.onClose();
  }
}
