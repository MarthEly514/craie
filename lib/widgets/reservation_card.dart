import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onDetails;
  final VoidCallback onLiberer;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onDetails,
    required this.onLiberer,
  });

  @override
  Widget build(BuildContext context) {
    final estSalle = reservation.type == TypeRessource.salle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.nom,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.encre,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (estSalle) ...[
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.discret),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  reservation.sousTitre,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.discret),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.encre,
                    side: const BorderSide(color: AppColors.encre, width: 1.5),
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(38),
                  ),
                  child: const Text('Détails',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onLiberer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.encre,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(38),
                  ),
                  child: const Text('Libérer',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}