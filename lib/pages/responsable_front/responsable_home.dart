import 'package:flutter/material.dart';
import 'materiels_page.dart';

import '../../widgets/app_bottom_nav.dart';
import 'reservations_page.dart';
import 'salles_page.dart';

class ResponsableHome extends StatefulWidget {
  const ResponsableHome({super.key});

  @override
  State<ResponsableHome> createState() => _ResponsableHomeState();
}

class _ResponsableHomeState extends State<ResponsableHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ReservationsPage(onReserver: () => setState(() => _index = 1)),
          // À remplacer par SallesPage() et MaterielPage() quand elles seront prêtes
          const SallesPage(),
          const MaterielsPage(),
          const Center(child: Text('Profil')),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
