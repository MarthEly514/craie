import '../../../../core/utils/time_slot.dart';
import '../../../resources/data/models/resource_model.dart';

class ReservationModel {
  final String id;
  final ResourceModel resource;
  final TimeSlot slot;
  final String motif;

  /// Class the resource is assigned to (filière of the responsable, or typed by the gestionnaire).
  final String classe;
  final String userId;
  final String userName;

  const ReservationModel({
    required this.id,
    required this.resource,
    required this.slot,
    required this.motif,
    required this.classe,
    required this.userId,
    required this.userName,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) => ReservationModel(
        id: json['id'] as String,
        resource: ResourceModel.fromJson(json['resource'] as Map<String, dynamic>),
        slot: TimeSlot(
          DateTime.parse(json['startAt'] as String).toLocal(),
          DateTime.parse(json['endAt'] as String).toLocal(),
        ),
        motif: json['motif'] as String,
        classe: json['classe'] as String,
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'resourceId': resource.id,
        'startAt': slot.start.toUtc().toIso8601String(),
        'endAt': slot.end.toUtc().toIso8601String(),
        'motif': motif,
        if (classe.isNotEmpty) 'classe': classe,
      };

}
