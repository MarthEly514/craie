import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/profile_view.dart';
import '../../../../shared/widgets/role_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/segmented_pills.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/data/models/user_model.dart';
import '../controllers/admin_controller.dart';
import '../../../../shared/widgets/primary_button.dart';


/// Admin home: accounts list + profile.
class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleShell(
      pages: [AccountsPage(), ProfileView()],
      icons: [Icons.group_outlined, Icons.person_outline],
    );
  }
}

class AccountsPage extends GetView<AdminController> {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.adminCreate),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau compte', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comptes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SearchField(onChanged: (v) => controller.query.value = v),
            const SizedBox(height: 14),
            Obx(() => SegmentedPills(
                  labels: const ['Tous', 'Gestionnaires', 'Responsables'],
                  selected: controller.filter.value,
                  onChanged: (i) => controller.filter.value = i,
                )),
            const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  final repo = controller.repository;

                  // 1. First load: nothing to show yet.
                  if (repo.isLoading.value && repo.users.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 2. The request failed: message + retry.
                  final error = repo.error.value;
                  if (error != null) {
                    return _ErrorState(message: error, onRetry: repo.load);
                  }

                  // 3. The list (pull down to reload).
                  final list = controller.accounts;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${list.length} comptes trouvés',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: repo.load,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _AccountTile(user: list[i]),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final UserModel user;

  const _AccountTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final suspended = user.isSuspended;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Get.toNamed(AppRoutes.adminUser, arguments: user.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: suspended ? const Color(0xFFF8F9F6) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: suspended ? 0.5 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user.subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            StatusBadge(label: suspended ? 'Suspendu' : 'Actif', positive: !suspended),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
    final String message;
    final VoidCallback onRetry;

    const _ErrorState({required this.message, required this.onRetry});

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      );
    }
  }

