import 'package:craie/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/time_slot.dart';
import '../../../../core/utils/ui.dart';
import '../../../../shared/services/session_service.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/data/models/user_model.dart';
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

  bool get isTaken => resources.find(resource.id)?.isTaken ?? false;

  /// Current reservation of this resource (reactive).
  ReservationModel? get reservation => reservations.forResource(resource.id);

  /// The gestionnaire can free anything; a responsable only their own.
  bool get canRelease {
    final r = reservation;
    return r != null && (isGestionnaire || r.userId == user?.id);
  }

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

  void _validate() =>
      timeError.value = validateSlot(_at(start.value), _at(end.value));

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

  Future<void> release() async {
    final r = reservation;
    if (r == null) return;
    if (!await confirmRelease(resource)) return;
    try {
      await reservations.release(r);
      await resources.load();
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
