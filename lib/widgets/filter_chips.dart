import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class FilterChips extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.map((label) {
          final actif = label == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: actif ? AppColors.encre : AppColors.fond,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: actif ? AppColors.encre : AppColors.pale,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: actif ? Colors.white : AppColors.discret,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}