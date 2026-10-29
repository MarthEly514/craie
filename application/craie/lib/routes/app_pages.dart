import 'package:get/get.dart';

import '../features/admin/presentation/bindings/admin_binding.dart';
import '../features/admin/presentation/views/account_created_view.dart';
import '../features/admin/presentation/views/admin_view.dart';
import '../features/admin/presentation/views/create_account_view.dart';
import '../features/admin/presentation/views/user_profile_view.dart';
import '../features/auth/presentation/bindings/login_binding.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/onboarding/presentation/bindings/onboarding_binding.dart';
import '../features/onboarding/presentation/views/onboarding_view.dart';
import '../features/reservations/presentation/bindings/assign_binding.dart';
import '../features/reservations/presentation/bindings/reservations_binding.dart';
import '../features/reservations/presentation/bindings/resource_detail_binding.dart';
import '../features/reservations/presentation/views/assign_view.dart';
import '../features/reservations/presentation/views/resource_detail_view.dart';
import '../features/reservations/presentation/views/responsable_view.dart';
import '../features/resources/presentation/bindings/resource_form_binding.dart';
import '../features/resources/presentation/bindings/resources_binding.dart';
import '../features/resources/presentation/views/new_resource_view.dart';
import '../features/resources/presentation/views/gestionnaire_view.dart';
import '../features/splash/presentation/views/splash_view.dart';
import '../shared/middlewares/auth_middleware.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminView(),
      binding: AdminBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adminCreate,
      page: () => const CreateAccountView(),
      binding: AdminBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adminCreated,
      page: () => const AccountCreatedView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.gestionnaire,
      page: () => const GestionnaireView(),
      binding: ResourcesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.responsable,
      page: () => const ResponsableView(),
      binding: ReservationsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adminUser,
      page: () => const UserProfileView(),
      binding: AdminBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.resourceDetail,
      page: () => const ResourceDetailView(),
      binding: ResourceDetailBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.newRoom,
      page: () => const NewRoomView(),
      binding: ResourceFormBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.newEquipment,
      page: () => const NewEquipmentView(),
      binding: ResourceFormBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.assign,
      page: () => const AssignView(),
      binding: AssignBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
