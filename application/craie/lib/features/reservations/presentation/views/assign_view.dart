import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/presentation/controllers/resource_list_controller.dart';
import '../../../resources/presentation/widgets/resource_list_body.dart';

/// Gestionnaire: pick a free room / equipment to assign to a class.
class AssignView extends StatelessWidget {
  const AssignView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ResourceListBody(
        controller: Get.find<ResourceListController>(tag: 'assign'),
        title: 'Attribuer',
        switchable: true,
      ),
    );
  }
}
