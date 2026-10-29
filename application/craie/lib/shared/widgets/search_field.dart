import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Rechercher',
        hintStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: const Icon(Icons.search, color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
