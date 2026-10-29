import 'package:craie/shared/services/storage_service.dart';
import 'package:get/get.dart';

import '../../../../network/api_client.dart';
  import '../../../../network/api_endpoints.dart';
  import '../../../../network/api_exception.dart';
  import '../../../../shared/services/session_service.dart';
  import '../models/user_model.dart';

  class AuthRepository {
    final ApiClient api;
    final SessionService session;

    AuthRepository(this.api, this.session);

    // connexion et stockage des tokens de l'utilisateur dans la session
    // renvoie une exception quand ca echoue
    Future<UserModel> login(String identifier, String password) async {
      final data = await api.post(
        ApiEndpoints.login,
        data: {'identifier': identifier.trim(), 'password': password},
      ) as Map<String, dynamic>;

      session.accessToken = data['accessToken'] as String;
      session.refreshToken = data['refreshToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      session.currentUser.value = user;
      return user;
    }

    /// Resumes the saved session. Returns the user, or null if there is none.
    Future<UserModel?> restoreSession() async {
      final saved = Get.find<StorageService>().refreshToken;
      if (saved == null) return null;
      session.refreshToken = saved;
      try {
        // No access token yet: the 401 makes ApiClient refresh it and replay this call.
        final data = await api.get(ApiEndpoints.me) as Map<String, dynamic>;
        final user = UserModel.fromJson(data);
        session.currentUser.value = user;
        return user;
      } on ApiException {
        return null;
      }
    }


    /// Tells the server to forget the refresh token, then clears the session.
    /// The local logout always happens, even if the server cannot be reached.
    Future<void> logout() async {
      final token = session.refreshToken;
      try {
        if (token != null) {
          await api.post(ApiEndpoints.logout, data: {'refreshToken': token});
        }
      } on ApiException {
        // Nothing to do: the session is cleared below anyway.
      }
      session.clear();
    }
  }
