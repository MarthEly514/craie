import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;

  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Rechercher',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.encre),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.discret),
        suffixIcon: const Icon(Icons.search, size: 22, color: AppColors.discret),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}