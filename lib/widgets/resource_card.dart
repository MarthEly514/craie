import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'status_chip.dart';

class ResourceCard extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final bool libre;
  final bool avecPin; // petite icône de lieu (pour les salles)
  final VoidCallback? onTap;

  const ResourceCard({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.libre,
    this.avecPin = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: libre ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.encre,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (avecPin) ...[
                            const Icon(Icons.location_on_outlined,
                                size: 15, color: AppColors.discret),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              sousTitre,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.discret,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusChip(libre: libre),
              ],
            ),
          ),
        ),
      ),
    );
  }
}