import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../network/api_endpoints.dart';
import '../../../../network/api_exception.dart';
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
      final data = await api.get(ApiEndpoints.resources) as List<dynamic>;
      resources.assignAll(data.map((j) => ResourceModel.fromJson(j as Map<String, dynamic>)));
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
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
