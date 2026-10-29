import 'package:get/get.dart';

import '../../../../core/utils/time_slot.dart';
import '../../../../network/api_client.dart';
import '../../../../network/api_endpoints.dart';
import '../../../../network/api_exception.dart';
import '../../../resources/data/models/resource_model.dart';
import '../models/reservation_model.dart';

class ReservationRepository {
  final ApiClient api;

  ReservationRepository(this.api);

  final reservations = <ReservationModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  ReservationModel? forResource(String resourceId) =>
      reservations.firstWhereOrNull((r) => r.resource.id == resourceId);

  /// The server returns only the reservations the user may see (own ones for a responsable).
  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final data = await api.get(ApiEndpoints.reservations) as List<dynamic>;
      reservations
          .assignAll(data.map((j) => ReservationModel.fromJson(j as Map<String, dynamic>)));
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Throws [ApiException] with a French message when the booking is refused.
  Future<void> book({
    required ResourceModel resource,
    required TimeSlot slot,
    required String motif,
    required String classe,
  }) async {
    // Instant feedback; the server checks the same rules again.
    final slotError = validateSlot(slot.start, slot.end);
    if (slotError != null) throw ApiException('INVALID_SLOT', slotError);

    final body = ReservationModel(
      id: '',
      resource: resource,
      slot: slot,
      motif: motif,
      classe: classe,
      userId: '',
      userName: '',
    ).toJson();
    final data = await api.post(ApiEndpoints.reservations, data: body);
    reservations.add(ReservationModel.fromJson(data as Map<String, dynamic>));
  }

  Future<void> release(ReservationModel r) async {
    await api.post(ApiEndpoints.releaseReservation(r.id));
    reservations.removeWhere((x) => x.id == r.id);
  }
}
