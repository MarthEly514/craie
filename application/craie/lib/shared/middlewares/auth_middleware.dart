import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../services/session_service.dart';

/// Redirects to the login page when no user is logged in.
/// TODO: also guard routes by role.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<SessionService>();
    return session.isLoggedIn ? null : const RouteSettings(name: AppRoutes.login);
  }
}
