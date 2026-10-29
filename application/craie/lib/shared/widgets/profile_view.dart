import 'package:craie/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../services/session_service.dart';
import 'primary_button.dart';

/// Profile tab. Admin sees identifier/password/role; the other roles
/// only see their name and role.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final user = session.currentUser.value;
    final isAdmin = user?.role == UserRole.admin;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        const Text('Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Informations personnelles',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.surface,
          child: Icon(Icons.person_outline, size: 36, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        InfoCard(rows: [
          if (isAdmin) ...[
            ('Identifiant', user?.identifier ?? ''),
            ('Mot de passe', '••••••'),
          ] else
            ('Nom complet', user?.name ?? ''),
          ('Role', user?.profileRole ?? ''),
        ]),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Se déconnecter',
          style: AppButtonStyle.danger,
          onPressed: () async {
            await Get.find<AuthRepository>().logout();
            Get.offAllNamed(AppRoutes.login);
          },
        ),
      ],
    );
  }
}

/// Grey card listing (label, value) rows.
class InfoCard extends StatelessWidget {
  final List<(String, String)> rows;

  const InfoCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
