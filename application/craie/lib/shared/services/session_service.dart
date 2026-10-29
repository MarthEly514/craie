import 'package:get/get.dart';

import '../../features/auth/data/models/user_model.dart';

/// Holds the logged-in user for the whole app.
class SessionService extends GetxService {
  String? accessToken;
  String? refreshToken;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  bool get isLoggedIn => currentUser.value != null;
  UserRole? get role => currentUser.value?.role;


// oubli de l'utilisateur  et de son token lors de l'expiration ou du logout
  void clear() {
  currentUser.value = null;
  accessToken = null;
  refreshToken = null;
  }
}
