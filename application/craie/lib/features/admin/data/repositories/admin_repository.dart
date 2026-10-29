import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../network/api_endpoints.dart';
import '../../../../network/api_exception.dart';
import '../../../auth/data/models/user_model.dart';

class AdminRepository {
  final ApiClient api;

  AdminRepository(this.api);

  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  UserModel? find(String id) => users.firstWhereOrNull((u) => u.id == id);

  /// Fetches all accounts. Failures are kept in [error] for the page to display.
  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final data = await api.get(ApiEndpoints.users) as List<dynamic>;
      users.assignAll(data.map((j) => UserModel.fromJson(j as Map<String, dynamic>)));
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(UserModel user) async {
    final data = await api.post(ApiEndpoints.users, data: user.toJson());
    users.add(UserModel.fromJson(data as Map<String, dynamic>));
  }

  /// Suspending also frees the user's reservations (done by the server).
  Future<void> setStatus(UserModel user, UserStatus status) async {
    final data = await api.patch(ApiEndpoints.user(user.id), data: {'status': status.json});
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) users[index] = UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(UserModel user) async {
    await api.delete(ApiEndpoints.user(user.id));
    users.removeWhere((u) => u.id == user.id);
  }
}
