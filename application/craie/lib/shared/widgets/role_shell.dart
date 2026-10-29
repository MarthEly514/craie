import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';

/// Holds the selected bottom-nav tab so any page can switch tabs.
class NavController extends GetxController {
  final index = 0.obs;
}

/// Page container with the green pill bottom navigation bar.
class RoleShell extends StatelessWidget {
  final List<Widget> pages;
  final List<IconData> icons;

  const RoleShell({super.key, required this.pages, required this.icons});

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(NavController());
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() => IndexedStack(index: nav.index.value, children: pages)),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Obx(() => Row(
                children: [
                  for (var i = 0; i < icons.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => nav.index.value = i,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: i == nav.index.value ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(icons[i], size: 22),
                        ),
                      ),
                    ),
                ],
              )),
        ),
      ),
    );
  }
}
