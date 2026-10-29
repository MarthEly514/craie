import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/segmented_pills.dart';
import '../controllers/admin_controller.dart';

class CreateAccountView extends GetView<AdminController> {
  const CreateAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Compte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: controller.formKey,
            child: Obx(() {
              final resp = controller.isResponsable.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedPills(
                    labels: const ['Responsable', 'Gestionnaire'],
                    selected: resp ? 0 : 1,
                    onChanged: (i) => controller.switchType(i == 0),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: controller.nameController,
                    label: 'Nom complet',
                    hint: 'Barry ALLEN',
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: controller.identifierController,
                    label: resp ? 'Numero matricule' : 'Adresse mail',
                    hint: resp ? 'xxxxxxxx' : 'exemple@gmail.com',
                    validator: Validators.required,
                  ),
                  if (resp) ...[
                    const SizedBox(height: 16),
                    const Text('Filiere',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: controller.filiere.value,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: CustomTextField.border(),
                        enabledBorder: CustomTextField.border(),
                      ),
                      items: [
                        for (final f in AppConstants.filieres)
                          DropdownMenuItem(value: f, child: Text(f)),
                      ],
                      onChanged: (v) => controller.filiere.value = v!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: controller.passwordController,
                    label: 'Mot de passe',
                    hint: '•••••',
                    validator: Validators.required,
                    suffix: TextButton(
                      onPressed: controller.generatePassword,
                      child: const Text('Générer',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Créer le compte',
                    style: AppButtonStyle.dark,
                    onPressed: controller.createAccount,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
