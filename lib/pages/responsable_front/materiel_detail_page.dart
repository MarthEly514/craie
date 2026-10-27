import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/materiel_controller.dart';
import '../../core/app_theme.dart';

class MaterielDetailPage extends StatefulWidget {
  final String id;

  const MaterielDetailPage({super.key, required this.id});

  @override
  State<MaterielDetailPage> createState() => _MaterielDetailPageState();
}

class _MaterielDetailPageState extends State<MaterielDetailPage> {
  final c = Get.find<MaterielController>();
  final _motifCtrl = TextEditingController();
  String _debut = '08:00';
  String _fin = '13:00';

  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _choisirHeure({required bool debut}) async {
    final parts = (debut ? _debut : _fin).split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null || !mounted) return;
    setState(() {
      if (debut) {
        _debut = _fmt(t);
      } else {
        _fin = _fmt(t);
      }
    });
  }

  void _reserver(String nom) {
    final motif = _motifCtrl.text.trim();
    if (motif.isEmpty) {
      Get.snackbar('Motif requis', 'Indique pour quel cours tu réserves.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_fin.compareTo(_debut) <= 0) {
      Get.snackbar('Créneau invalide',
          "L'heure de fin doit être après l'heure de début.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    c.reserver(widget.id, debut: _debut, fin: _fin, motif: motif);
    Get.snackbar('Réservé', '$nom : $_debut à $_fin',
        snackPosition: SnackPosition.BOTTOM);
  }

  void _liberer(String nom) {
    c.liberer(widget.id);
    Get.back();
    Get.snackbar('Libéré', '$nom a été libéré',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          final m = c.parId(widget.id);
          final reserve = m.parMoi;
          final debut = reserve ? (m.debut ?? _debut) : _debut;
          final fin = reserve ? (m.fin ?? _fin) : _fin;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.chevron_left,
                          size: 30, color: AppColors.encre),
                    ),
                    const Text(
                      'Matériel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.encre,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nom,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: AppColors.encre,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.reference,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.discret),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Text(
                              'État du matériel :',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.encre,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.limeClair,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                m.etat,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.encre,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Créneau de réservation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.encre,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _HeurePill(
                                heure: debut,
                                onTap: reserve
                                    ? null
                                    : () => _choisirHeure(debut: true),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('à',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.encre)),
                            ),
                            Expanded(
                              child: _HeurePill(
                                heure: fin,
                                onTap: reserve
                                    ? null
                                    : () => _choisirHeure(debut: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Motif',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.encre,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (reserve)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 12),
                            child: Text(
                              m.motif ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.discret),
                            ),
                          )
                        else
                          TextField(
                            controller: _motifCtrl,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.encre),
                            decoration: InputDecoration(
                              hintText: 'Ex : Cours de bases de données',
                              hintStyle: const TextStyle(
                                  fontSize: 14, color: AppColors.discret),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(99),
                                borderSide: const BorderSide(
                                    color: AppColors.pale, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(99),
                                borderSide: const BorderSide(
                                    color: AppColors.encre, width: 1.5),
                              ),
                            ),
                          ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: reserve
                                ? () => _liberer(m.nom)
                                : () => _reserver(m.nom),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  reserve ? AppColors.encre : AppColors.lime,
                              foregroundColor:
                                  reserve ? Colors.white : AppColors.encre,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              reserve ? 'Libérer' : 'Réserver',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        if (reserve) ...[
                          const SizedBox(height: 18),
                          const Center(
                            child: Text(
                              'Le matériel sera automatiquement libéré\naprès échéance',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.discret),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HeurePill extends StatelessWidget {
  final String heure;
  final VoidCallback? onTap;

  const _HeurePill({required this.heure, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          heure,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.encre,
          ),
        ),
      ),
    );
  }
}