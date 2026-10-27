import 'package:flutter/material.dart';

class AppColors {
  static const fond = Colors.white;
  static const surface = Color(0xFFF0F3EC);
  static const surface2 = Color(0xFFE4EADC);
  static const bord = Color(0xFFECECEA);
  static const encre = Color(0xFF173300);
  static const texte = Color(0xFF182011);
  static const discret = Color(0xFF66735D);
  static const pale = Color(0xFFA3AA9C);
  static const lime = Color(0xFF9FE970);
  static const limeClair = Color(0xFFE6F8D8);
  static const corail = Color(0xFFC4432B);
  static const corailClair = Color(0xFFFDE9E4);

  // Anciens noms, pour que les fichiers déjà créés compilent encore
  static const vert = lime;
  static const rouge = corail;
  static const fondCarte = surface;
  static const fondChamp = surface;
  static const texteSecondaire = discret;
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'WuraMi',
        scaffoldBackgroundColor: AppColors.fond,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lime,
          primary: AppColors.encre,
        ),
      );
}