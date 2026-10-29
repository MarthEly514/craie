import 'package:craie/core/utils/time_slot.dart';
import 'package:craie/features/auth/data/models/user_model.dart';
  import 'package:craie/features/reservations/data/models/reservation_model.dart';
  import 'package:craie/features/resources/data/models/resource_model.dart';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    group('UserModel', () {
      test('reads a responsable with its filière', () {
        final json = {
          'id': 'u1',
          'fullName': 'Ariane ALIZEE',
          'identifier': '10080345',
          'role': 'responsable',
          'filiere': 'IM-3',
          'status': 'active',
        };

        final user = UserModel.fromJson(json);

        expect(user.role, UserRole.responsableFiliere);
        expect(user.filiere, 'IM-3');
        expect(user.password, '');
      });

      test('responsable de filiere avec filiere null (creation I guess)', (){
        final json = {
          'id': 'u1',
          'fullName': 'Rachel ROTH',
          'identifier': '10080365',
          'role': 'responsable',
          'filiere': null,
          'status': 'active',
        };
        final user = UserModel.fromJson(json);

        expect(user.role, UserRole.responsableFiliere);
        expect(user.filiere, null);
        expect(user.password, '');
      });

      

      test('rejects an unknown role', () {
        final json = {
          'id': 'u1',
          'fullName': 'X',
          'identifier': 'x',
          'role': 'boss',
          'status': 'active',
        };

        expect(() => UserModel.fromJson(json), throwsFormatException);
      });

    });
    group('ResourceModel', () {
      test('toJson of room', () {
        const room = ResourceModel(
          id: 'r1',
          name: 'Salle A4-5',
          type: ResourceType.room,
          zone: 'FSA',
          location: 'Godomey',
          amenities: ["Projecteur", "Climatisation"]
        );

        final json = room.toJson();

        expect(json['amenities'], ["Projecteur", "Climatisation"]);
      });
      test('infos manquantes', (){
        final json = {
          'id': 'res1',
          'name': 'Vidéoprojecteur',
          'type': 'equipment',
          'amenities': null,
          'zone': null,
          'location': null,
        };


        final room = ResourceModel.fromJson(json);

        expect(room.amenities, isEmpty);
        expect(room.zone, '');
      });

      test('equipment raise FormatException', (){
        final json = {
          'id': 'res1',
          'name': 'Vidéoprojecteur',
          'type': 'equipement',
        };

        expect(() => ResourceModel.fromJson(json), throwsFormatException);
      });
    });
    group('ReservationModel', () {
      test('reservation sans classe', () {
        final reservation = ReservationModel(
          id: 'r1',
          resource: ResourceModel(id: 'rs1', name: 'Salle B12', type: ResourceType.room),
          slot: TimeSlot(DateTime(2026, 10, 28, 8), DateTime(2026, 10, 28, 10)),
          motif: 'Cours d\'anglais',
          classe: '',
          userId: 'u2',
          userName: 'Raven ROTH',
          
        );

        final json = reservation.toJson();

        expect(json['resourceId'], 'rs1');
        expect(json.containsKey('classe'), false);
        expect(
          DateTime.parse(json['startAt']).isAtSameMomentAs(DateTime(2026, 10, 28, 8)),
          true,
        );
      });

      test('userid null', () {
        final json = {
          'id': 'b1',
          'resource': {'id': 'r1', 'name': 'Salle B12', 'type': 'room'},
          'startAt': '2026-10-28T07:00:00.000Z',
          'endAt': '2026-10-28T09:00:00.000Z',
          'motif': 'Cours de base de donnees',
          'classe': 'IM-3',
          'userId': null,
          'userName': 'Raven ROTH',
        };
        final reservation = ReservationModel.fromJson(json);

        expect(reservation.slot.start, DateTime.utc(2026, 10, 28, 7).toLocal());
        expect(reservation.userId, '');
        expect(reservation.toJson()['startAt'], '2026-10-28T07:00:00.000Z');
      });
    });
  }
