import 'package:craie/core/utils/ui.dart';
import 'package:craie/network/api_exception.dart';
import 'package:get/get.dart';

import '../../../reservations/data/repositories/reservation_repository.dart';
import '../../data/models/resource_model.dart';
import '../../data/repositories/resource_repository.dart';

/// State of a searchable / filterable list of resources (rooms or equipment).
/// Several instances exist (distinguished by tag): the gestionnaire's
/// resources tab, the assignment picker, and the responsable's two tabs.
class ResourceListController extends GetxController {
  final ResourceRepository resources;
  final ReservationRepository reservations;

  final Rx<ResourceType> type;
  final query = ''.obs;

  /// Selected zone (rooms) or category (equipment); null = all.
  final filter = Rxn<String>();

  ResourceListController(this.resources, this.reservations, ResourceType initial)
      : type = initial.obs;

  bool isTaken(ResourceModel r) => r.isTaken;

  List<ResourceModel> get ofType =>
      resources.resources.where((r) => r.type == type.value).toList();

  /// Distinct zones / categories available for filtering.
  List<String> get options =>
      ofType.map((r) => r.filterKey).where((k) => k.isNotEmpty).toSet().toList();

  List<ResourceModel> get items {
    final q = query.value.toLowerCase();
    return ofType
        .where((r) =>
            (filter.value == null || r.filterKey == filter.value) &&
            r.name.toLowerCase().contains(q))
        .toList();
  }

  void setType(ResourceType t) {
    type.value = t;
    filter.value = null;
  }


  Future<void> remove(ResourceModel r) async {
    try {
      await resources.remove(r);
      await reservations.load();
    } on ApiException catch (e) {
      showMessage('Erreur', e.message);
    }
  }

}
