import 'package:craie/core/constants/app_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../core/utils/time_slot.dart';
import '../../../../network/api_client.dart';
import '../../../../network/api_endpoints.dart';
import '../../../../network/api_exception.dart';
import '../models/availability.dart';
import '../models/resource_model.dart';

class ResourceRepository {
  final ApiClient api;

  ResourceRepository(this.api);

  final resources = <ResourceModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  ResourceModel? find(String id) => resources.firstWhereOrNull((r) => r.id == id);

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final now = DateTime.now();
      final dayEnd = DateTime(now.year, now.month, now.day, AppConstants.closingHour);
      final data = await api.get(
        ApiEndpoints.resources,
        // The server returns each resource's bookings overlapping [from, to].
        query: {
          'from': now.toUtc().toIso8601String(),
          'to': dayEnd.toUtc().toIso8601String(),
        },
      ) as List<dynamic>;
      resources.assignAll(data.map((j) => ResourceModel.fromJson(j as Map<String, dynamic>)));
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
    // debugPrint(resources.map((r) => '${r.name}: ${r.todaySlots.length}').join(' | '));
  }

  Future<void> add(ResourceModel r) async {
    final data = await api.post(ApiEndpoints.resources, data: r.toJson());
    resources.add(ResourceModel.fromJson(data as Map<String, dynamic>));
  }

  /// The server also frees the resource's reservations.
  Future<void> remove(ResourceModel r) async {
    await api.delete(ApiEndpoints.resource(r.id));
    resources.removeWhere((x) => x.id == r.id);
  }
}
