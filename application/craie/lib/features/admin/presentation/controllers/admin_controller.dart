import 'dart:math';

import 'package:craie/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/repositories/admin_repository.dart';

class AdminController extends GetxController {
  final AdminRepository repository;

  AdminController(this.repository);

  // Accounts list
  final filter = 0.obs; // 0 all, 1 gestionnaires, 2 responsables
  final query = ''.obs;

  List<UserModel> get accounts {
    final q = query.value.toLowerCase();
    return repository.users.where((u) {
      if (u.role == UserRole.admin) return false;
      if (filter.value == 1 && u.role != UserRole.gestionnaire) return false;
      if (filter.value == 2 && u.role != UserRole.responsableFiliere) return false;
      return u.name.toLowerCase().contains(q);
    }).toList();
  }

  // Account creation
  final formKey = GlobalKey<FormState>();
  final isResponsable = true.obs;
  final nameController = TextEditingController();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  final filiere = AppConstants.filieres.first.obs;


  @override
  void onInit() {
    super.onInit();
    repository.load();
  }
  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Erreur', e.message,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    }
  }


  void generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    passwordController.text =
        List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  void switchType(bool responsable) {
    isResponsable.value = responsable;
    identifierController.clear();
  }

  Future<void> createAccount() async {
    if (!formKey.currentState!.validate()) return;
    final ok = await _run(() => repository.create(UserModel(
          id: '',
          name: nameController.text.trim(),
          identifier: identifierController.text.trim(),
          password: passwordController.text,
          role: isResponsable.value ? UserRole.responsableFiliere : UserRole.gestionnaire,
          filiere: isResponsable.value ? filiere.value : null,
        )));
    if (!ok) return;
    nameController.clear();
    identifierController.clear();
    passwordController.clear();
    Get.offNamed(AppRoutes.adminCreated);
  }

  UserModel? find(String id) => repository.find(id);


  Future<void> suspend(UserModel u) async {
    final confirmed = await showConfirmDialog(
      title: 'Suspendre ce compte?',
      message:
          '${u.name} ne pourra plus se connecter. Ses réservations en cours seront libérées.',
      confirmLabel: 'Suspendre ${u.name.split(' ').first}',
    );
    if (confirmed) await _run(() => repository.setStatus(u, UserStatus.suspended));
  }


  Future<void> reactivate(UserModel u) =>
        _run(() => repository.setStatus(u, UserStatus.active));

  Future<void> delete(UserModel u) async {
    final confirmed = await showConfirmDialog(
      title: 'Supprimer ce compte?',
      message: 'Cette action est définitive. L\'historique des réservations est conservé.',
      confirmLabel: 'Supprimer définitivement',
      danger: true,
    );
    if (!confirmed) return;
    if (await _run(() => repository.delete(u))) Get.back();
  }


  @override
  void onClose() {
    nameController.dispose();
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
