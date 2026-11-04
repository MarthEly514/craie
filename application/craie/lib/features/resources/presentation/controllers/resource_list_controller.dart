import 'package:craie/core/utils/ui.dart';
import 'package:craie/network/api_exception.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../reservations/data/repositories/reservation_repository.dart';
import '../../data/models/availability.dart';
import '../../data/models/resource_model.dart';
import '../../data/repositories/resource_repository.dart';
import 'dart:async';

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

  final now = DateTime.now().obs;
  Timer? _ticker;

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

  Availability availabilityOf(ResourceModel r) {
    final n = now.value;
    return r.availability(n, DateTime(n.year, n.month, n.day, AppConstants.closingHour));
  }

  void setType(ResourceType t) {
    type.value = t;
    filter.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => now.value = DateTime.now());
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
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

