import 'package:craie/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_slot.dart';
import '../../../../core/utils/ui.dart';
import '../../../../shared/services/session_service.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../resources/data/models/availability.dart';
import '../../../resources/data/models/resource_model.dart';
import '../../../resources/data/repositories/resource_repository.dart';
import '../../data/models/reservation_model.dart';
import '../../data/repositories/reservation_repository.dart';
import 'reservations_controller.dart';

/// Detail of a room / equipment: shows the booking form when it is free,
/// the current reservation (with "Libérer") when it is taken.
/// Route argument: the resource id.
class ResourceDetailController extends GetxController {
  final ResourceRepository resources;
  final ReservationRepository reservations;
  final SessionService session;

  ResourceDetailController(this.resources, this.reservations, this.session);

  late final ResourceModel resource;

  final start = const TimeOfDay(hour: 8, minute: 0).obs;
  final end = const TimeOfDay(hour: 13, minute: 0).obs;
  final classe = TextEditingController();
  final motif = TextEditingController();

  UserModel? get user => session.currentUser.value;
  bool get isGestionnaire => user?.role == UserRole.gestionnaire;

  @override
  void onInit() {
    super.onInit();
    resource = resources.find(Get.arguments as String)!;
  }

  /// Validation message for the chosen slot (null = valid).
  final timeError = Rxn<String>();

  DateTime _at(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  void _validate() {
    final slot = TimeSlot(_at(start.value), _at(end.value));
    timeError.value = validateSlot(slot.start, slot.end) ?? _conflict(slot);
  }

  String? _conflict(TimeSlot s) {
    for (final t in takenSlots) {
      if (s.overlaps(t)) {
        return 'Ce créneau chevauche ${formatHm(t.start)} – ${formatHm(t.end)}';
      }
    }
    return null;
  }

  /// Opens the time selector; the new value is applied even if invalid so the
  /// error is displayed on the time boxes.
  Future<void> pickTime(BuildContext context, bool isStart) async {
    final current = isStart ? start : end;
    final picked = await showTimePicker(
      context: context,
      initialTime: current.value,
      helpText: isStart ? 'HEURE DE DÉBUT' : 'HEURE DE FIN',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    current.value = picked;
    _validate();
  }

  /// Occupied slots from now on, earliest first
  List<TimeSlot> get takenSlots {
    final fresh = resources.find(resource.id) ?? resource;
    final now = DateTime.now();
    return fresh.todaySlots.where((s) => s.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }


  Future<void> book() async {
    if (motif.text.trim().isEmpty ||
        (isGestionnaire && classe.text.trim().isEmpty)) {
      showMessage('Champs requis', 'Renseignez la classe et le motif');
      return;
    }
    _validate();
    if (timeError.value != null) return;
    try {
      await reservations.book(
        resource: resource,
        slot: TimeSlot(_at(start.value), _at(end.value)),
        motif: motif.text.trim(),
        classe: isGestionnaire ? classe.text.trim() : (user?.filiere ?? ''),
      );
      await resources.load();
    } on ApiException catch (e) {
      showMessage('Réservation impossible', e.message);
    }
  }

  List<ReservationModel> get resourceReservations => reservations.allForResource(resource.id);

  /// The gestionnaire can free any slot; a responsable only their own.
  bool canReleaseReservation(ReservationModel r) => isGestionnaire || r.userId == user?.id;

  Availability get availability {
    final n = DateTime.now();
    final fresh = resources.find(resource.id) ?? resource;
    return fresh.availability(n, DateTime(n.year, n.month, n.day, AppConstants.closingHour));
  }

  Future<void> releaseReservation(ReservationModel r) async {
    if (!await confirmRelease(resource)) return;
    try {
      await reservations.release(r);
      await resources.load(); // refreshes the slots and the status
    } on ApiException catch (e) {
      showMessage('Erreur', e.message);
    }
  }


  Future<void> deleteResource() async {
    final ok = await showConfirmDialog(
      title: 'Supprimer la ressource?',
      message:
          '${resource.name} sera supprimé définitivement. Ses réservations en cours seront libérées.',
      confirmLabel: 'Supprimer définitivement',
      danger: true,
    );
    if (!ok) return;
    try {
      await resources.remove(resource);
      await reservations.load();
      Get.back();
    } on ApiException catch (e) {
      showMessage('Erreur', e.message);
    }
  }


  @override
  void onClose() {
    classe.dispose();
    motif.dispose();
    super.onClose();
  }
}
