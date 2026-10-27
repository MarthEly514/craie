import 'models/salle.dart';

const sallesDemo = <Salle>[
  // Réservée par le responsable connecté (liée à l'onglet Réservations)
  Salle(
    id: 's1',
    nom: 'Salle A2-2',
    zone: 'Zone master',
    lieu: 'Zone master (Zogbadjè)',
    equipements: ['Climatiseur', 'Électricité'],
    estLibre: false,
    parMoi: true,
    debut: '08:00',
    fin: '13:00',
    motif: 'Cours de bases de données',
  ),
  Salle(
    id: 's2',
    nom: 'Salle A2-1',
    zone: 'Zone master',
    lieu: 'Zone master (Zogbadjè)',
    equipements: ['Climatiseur', 'Électricité'],
    estLibre: true,
  ),
  Salle(
    id: 's3',
    nom: 'Salle G2',
    zone: 'Zone master',
    lieu: 'Zone master (Zogbadjè)',
    equipements: ['Électricité'],
    estLibre: true,
  ),
  Salle(
    id: 's4',
    nom: 'Salle F1',
    zone: 'Zone master',
    lieu: 'Zone master (Zogbadjè)',
    equipements: ['Climatiseur'],
    estLibre: false,
  ),
  Salle(
    id: 's5',
    nom: 'Salle F2',
    zone: 'Zone master',
    lieu: 'Zone master (Zogbadjè)',
    equipements: ['Électricité'],
    estLibre: false,
  ),
];