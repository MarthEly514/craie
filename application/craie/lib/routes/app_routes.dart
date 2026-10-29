import 'package:craie/features/auth/data/models/user_model.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  // Here, we nanage routes for startup
  static String homeFor(UserRole role) => switch (role) {
        UserRole.admin => admin,
        UserRole.gestionnaire => gestionnaire,
        UserRole.responsableFiliere => responsable,
      };


  // Role home pages
  static const String admin = '/admin';
  static const String gestionnaire = '/gestionnaire';
  static const String responsable = '/responsable';

  // Admin sub-pages
  static const String adminCreate = '/admin/create';
  static const String adminCreated = '/admin/created';
  static const String adminUser = '/admin/user';

  // Resources / reservations sub-pages
  static const String resourceDetail = '/resource';
  static const String newRoom = '/resource/new-room';
  static const String newEquipment = '/resource/new-equipment';
  static const String assign = '/gestionnaire/assign';
}
