import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/data/models/user_model.dart';

/// In-memory accounts, seeded with the test admin.
/// TODO: replace with the real storage chosen for the project.
class UserStore extends GetxService {
  final users = <UserModel>[
    UserModel(
      id: '0',
      name: 'Administrateur',
      identifier: AppConstants.adminIdentifier,
      password: AppConstants.adminPassword,
      role: UserRole.admin,
    ),
    UserModel(id: '1', name: 'Ariane ALIZEE', identifier: '10080345', password: '1234', role: UserRole.responsableFiliere, filiere: 'IM-3'),
    UserModel(id: '2', name: 'Logan SEN', identifier: '20240002', password: '1234', role: UserRole.responsableFiliere, filiere: 'SI-2'),
    UserModel(id: '3', name: 'Seth AKPLOGAN', identifier: 'seth@mail.com', password: '1234', role: UserRole.gestionnaire),
    UserModel(id: '4', name: 'Alvine PAGE', identifier: '20240004', password: '1234', role: UserRole.responsableFiliere, filiere: 'GL-3', status: UserStatus.suspended),
    UserModel(id: '6', name: 'Miguel MIGAN', identifier: '10080346', password: '1234', role: UserRole.responsableFiliere, filiere: 'IM-2'),
    UserModel(id: '5', name: 'Roman KIKI', identifier: 'roman@mail.com', password: '1234', role: UserRole.gestionnaire, status: UserStatus.suspended),
  ].obs;

  UserModel? find(String identifier, String password) =>
      users.firstWhereOrNull((u) => u.identifier == identifier && u.password == password);

  bool exists(String identifier) => users.any((u) => u.identifier == identifier);

  void add(UserModel user) => users.add(user);

  void remove(UserModel user) => users.remove(user);

  void toggleSuspended(UserModel user) {
    user.status = user.isSuspended ? UserStatus.active : UserStatus.suspended;
    users.refresh();
  }
}
