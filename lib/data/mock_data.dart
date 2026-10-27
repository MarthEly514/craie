import 'models/reservation.dart';

const reservationsDemo = <Reservation>[
  Reservation(
    id: 's1',
    nom: 'Salle A2-2',
    sousTitre: 'Zone master (Zogbadjè)',
    type: TypeRessource.salle,
  ),
  Reservation(
    id: 'm5',
    nom: 'Projecteur EpsonC10',
    sousTitre: 'Epson C10-V12',
    type: TypeRessource.materiel,
  ),
  Reservation(
    id: 'm6',
    nom: 'Rallonge_5',
    sousTitre: 'Rallonge 15m grise',
    type: TypeRessource.materiel,
  ),
];
