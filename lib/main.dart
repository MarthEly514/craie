import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/app_theme.dart';
import 'pages/responsable_front/reservations_page.dart';
import 'core/app_theme.dart';
import 'pages/responsable_front/responsable_home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Craie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ResponsableHome(),
    );
  }
}
